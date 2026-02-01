# 🔍 ORDER CREATION DATA FLOW - CODE DEEP DIVE

## Complete Data Journey with Code Examples

---

## STEP 1: Prepare Order Items
**File:** `lib/services/razorpay_payment_service.dart` (Lines 61-160)

### What Data is Prepared:

```dart
Future<List<Map<String, dynamic>>> _prepareOrderItems(
  List<CartItem> cartItems,
  {bool isBuyNow = false, Map<String, dynamic>? buyNowData}
) async {
  
  // ============================================================
  // SCENARIO 1: Buy Now Flow
  // ============================================================
  if (isBuyNow && buyNowData != null) {
    final product = buyNowData['product'];      // Product model
    final quantity = buyNowData['quantity'];
    final selectedColor = buyNowData['selectedColor'];
    
    // ❌ MISSING: skuId (in buyNowData, but not extracted)
    // ❌ MISSING: sellingPrice (for this SKU)
    // ❌ MISSING: variantAttributes (size, binding, etc)
    
    return [{
      'productId': product.productId,           // ← Product ID (ok)
      'quantity': quantity,
      'name': product.name,
      'price': product.price,                   // ← Base price (missing selling price)
      'productImage': product.displayImage,
      'discountPrice': product.price,
      if (selectedColor != null) 'selectedColor': selectedColor,  // ← Only color
    }];
  }
  
  // ============================================================
  // SCENARIO 2: Regular Cart Checkout
  // ============================================================
  else {
    // Get CartItems from local database
    // Each CartItem has: productId (SKU), quantity, selectedColor
    final cartProductIds = cartItems.map((item) => item.productId).toList();
    // Example: ['NB-BLUE-P1', 'NB-RED-P1', 'PENCIL-HB']
    
    // Fetch Product details for these IDs
    final products = await _productService.getProductsByIds(cartProductIds);
    // This returns Product models, but cartItems have SKU IDs!
    // So matching might fail or return generic product data
    
    final orderItems = cartItems.map((cartItem) {
      final product = products.firstWhereOrNull(
        (p) => p.productId == cartItem.productId
      );
      
      if (product != null) {
        return {
          'productId': cartItem.productId,  // ← This is SKU ID, not product ID!
          'quantity': cartItem.quantity,
          'name': product.name,             // ← Product name (generic)
          'price': product.price,           // ← Product price (may not be SKU price)
          'productImage': product.displayImage,
          'discountPrice': product.price,
          if (cartItem.selectedColor != null) 'selectedColor': cartItem.selectedColor,
        };
      }
      
      // Fallback if product not found
      return {
        'productId': cartItem.productId,
        'quantity': cartItem.quantity,
        'name': 'Product ${cartItem.productId}',
        'price': 0.0,
        'productImage': '',
        'discountPrice': 0.0,
      };
    }).toList();
    
    print('🔍 Prepared ${orderItems.length} order items');
    return orderItems;
  }
}
```

### Data Prepared (Example):
```dart
// Item prepared for a blue notebook with quantity 2
[
  {
    'productId': 'NB-BLUE-P1',          // ← SKU ID (confusing!)
    'quantity': 2,
    'name': 'Notebook',                 // ← Product name (generic)
    'price': 100.0,                     // ← Product price
    'productImage': 'https://...',
    'discountPrice': 100.0,
    'selectedColor': 'Blue'             // ← Only color, deprecated field
  }
]
```

---

## STEP 2: Send to Firebase Function
**File:** `lib/services/razorpay_payment_service.dart` (Lines 230-275)

### What Payload is Sent:

```dart
// ============================================================
// CONSTRUCT PAYLOAD
// ============================================================
final amountSummary = {
  'subTotal': subTotal,                 // ✅ Item prices total
  'discount': discount,                 // ✅ Coupon discount
  'walletUsed': walletUsed,             // ✅ Wallet amount
  'deliveryFee': deliveryFee,           // ✅ Shipping cost
  'finalPayable': finalPayable,         // ✅ Amount to pay
  'totalOrderAmount': totalAmount,      // ✅ Total order value
};

final addressData = {
  'id': deliveryAddress.id,
  'name': deliveryAddress.name,         // ✅ Full name
  'phoneNumber': deliveryAddress.phoneNumber,  // ✅ Phone
  'street': deliveryAddress.street,     // ✅ Street
  'city': deliveryAddress.city,         // ✅ City
  'state': deliveryAddress.state,       // ✅ State
  'postalCode': deliveryAddress.postalCode,   // ✅ Postal code
  'country': deliveryAddress.country,   // ✅ Country
};

// ============================================================
// CALL FIREBASE FUNCTION
// ============================================================
final callable = _functions.httpsCallable('createOrder');

final result = await callable.call({
  'items': items,                       // ← Items from Step 1
  'amountSummary': amountSummary,       // ← All amounts ✅
  'currency': 'INR',
  'paymentMode': paymentMode,           // ← razorpay/cod/wallet/partial_wallet
  'deliveryAddress': addressData,       // ← Address ✅
  'couponCode': couponCode,             // ← Coupon code (if any)
});
```

### Actual Function Call Parameters:

```javascript
// Payload sent to Firebase Function:
{
  items: [
    {
      productId: 'NB-BLUE-P1',      // ← SKU ID
      quantity: 2,
      name: 'Notebook',
      price: 100.0,
      productImage: 'https://...',
      discountPrice: 100.0,
      selectedColor: 'Blue'         // ← DEPRECATED
    }
  ],
  amountSummary: {
    subTotal: 200,                  // 2 × 100
    discount: 20,                   // Coupon discount
    walletUsed: 50,                 // Wallet payment
    deliveryFee: 100,               // Shipping
    finalPayable: 230,              // 200 + 100 - 20 - 50
    totalOrderAmount: 280           // Original total before wallet
  },
  currency: 'INR',
  paymentMode: 'razorpay',
  deliveryAddress: {
    name: 'John Doe',
    phoneNumber: '9876543210',
    street: '123 Main Street',
    city: 'Delhi',
    state: 'Delhi',
    postalCode: '110001',
    country: 'India'
  },
  couponCode: 'SAVE20'
}
```

---

## STEP 3: Firebase Cloud Function Receives Data
**File:** `functions/razorpay.ts` (Lines 60-170)

### What Firebase Function Does:

```typescript
export const createOrder = onCall(
  { cors: true },
  async (request) => {
    try {
      // ============================================================
      // 1. EXTRACT AND VALIDATE DATA
      // ============================================================
      const userId = request.auth.uid;
      
      const {
        items,               // Items from frontend ✅
        amountSummary,       // Amount breakdown ✅
        paymentMode,         // Payment type ✅
        couponCode,          // Coupon code ✅
        deliveryAddress,     // Address ✅
        currency = 'INR'
      } = request.data;

      console.log('🔍 Firebase Function: Creating order for user:', userId);
      console.log('💰 Amount Summary:', {
        subTotal: amountSummary.subTotal,
        discount: amountSummary.discount,
        walletUsed: amountSummary.walletUsed,
        deliveryFee: amountSummary.deliveryFee,
        finalPayable: amountSummary.finalPayable,
        totalOrderAmount: amountSummary.totalOrderAmount
      });

      // ============================================================
      // 2. VALIDATE AMOUNTS
      // ============================================================
      const subTotal = amountSummary.subTotal || 0;
      const discountAmount = amountSummary.discount || 0;
      const walletAmountUsed = amountSummary.walletUsed || 0;
      const deliveryFee = amountSummary.deliveryFee || 0;
      const finalAmount = amountSummary.finalPayable || 0;
      const totalOrderAmount = amountSummary.totalOrderAmount || 0;

      // Validate: finalAmount = subTotal + deliveryFee - discount - wallet
      const expectedFinalAmount = 
        subTotal + deliveryFee - discountAmount - walletAmountUsed;
      
      if (Math.abs(finalAmount - expectedFinalAmount) > 0.01) {
        throw new Error(
          `Final amount mismatch: 
           Received: ${finalAmount}, 
           Expected: ${expectedFinalAmount}
           (${subTotal} + ${deliveryFee} - ${discountAmount} - ${walletAmountUsed})`
        );
      }

      // ============================================================
      // 3. GENERATE IDS
      // ============================================================
      const orderId = `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const paymentId = `PAY${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const deliveryId = `DEL${Date.now()}${Math.floor(Math.random() * 1000)}`;

      console.log('📋 Generated IDs:', {
        orderId,
        paymentId,
        deliveryId
      });

      // ============================================================
      // 4. PREPARE DOCUMENTS FOR FIRESTORE
      // ============================================================
      await db.runTransaction(async (transaction) => {
        const now = new Date();

        // ─────────────────────────────────────────────────────────
        // DOCUMENT 1: payments collection
        // ─────────────────────────────────────────────────────────
        const paymentRef = db.collection('payments').doc(paymentId);
        const paymentData = {
          paymentId,
          orderId,
          userId,
          method: paymentMode,
          status: paymentStatus,
          gateway: gateway,
          createdAt: now,

          // ✅ ALL AMOUNTS SAVED
          amountBreakdown: {
            subTotal,                  // ✅
            discount: discountAmount,  // ✅
            deliveryFee,               // ✅
            walletUsed: walletAmountUsed,  // ✅
            finalAmount,               // ✅
            totalOrderAmount           // ✅
          },

          // ✅ COUPON INFO SAVED
          couponInfo: couponCode ? {
            code: couponCode,
            discountApplied: discountAmount,
            appliedAt: now
          } : null,

          // ✅ WALLET INFO SAVED
          walletInfo: (paymentMode === 'wallet' || 
                       paymentMode === 'partial_wallet') ? {
            amountUsed: walletAmountUsed,
            isPartialPayment: paymentMode === 'partial_wallet',
            remainingAmount: paymentMode === 'partial_wallet' ? 
                           finalAmount : 0
          } : null
        };

        transaction.set(paymentRef, paymentData);
        console.log('✅ Created payments document');

        // ─────────────────────────────────────────────────────────
        // DOCUMENT 2: orders collection ← MAIN DOCUMENT
        // ─────────────────────────────────────────────────────────
        const orderRef = db.collection('orders').doc(orderId);
        const orderData = {
          orderId,
          userId,
          paymentMode,
          paymentId,
          deliveryId,
          status: orderStatus,
          createdAt: now,
          updatedAt: now,

          // ============================================================
          // ITEMS STRUCTURE - THIS IS THE PROBLEM!
          // ============================================================
          items: items.map((item: any) => ({
            // ❌ PROBLEM: productId field is ambiguous
            productId: item.productId,  // Could be product ID or SKU ID
            
            name: item.name,            // ✅ Product name
            price: item.price,          // ✅ Price (but is it base or selling?)
            quantity: item.quantity,    // ✅ Quantity
            subtotal: item.price * item.quantity,  // ✅ Subtotal
            productImage: item.productImage || null,  // ✅ Image
            discountPrice: item.discountPrice || item.price,  // ⚠️ Generic
            totalPrice: (item.discountPrice || item.price) * item.quantity,
            
            // ❌ MISSING: No separate skuId
            // ❌ MISSING: No sellingPrice
            // ⚠️ PROBLEM: Variant data in deprecated field
            selectedColor: item.selectedColor,  // ← DEPRECATED location
            
            itemMetadata: {
              originalPrice: item.price,
              // ❌ MISSING: sellingPrice
              appliedDiscount: item.discountPrice ? 
                             (item.price - item.discountPrice) : 0,
              // ❌ MISSING: variantAttributes
              category: item.category || null,
              brand: item.brand || null
            }
          })),

          // ✅ ALL AMOUNTS SAVED CORRECTLY
          amountBreakdown: {
            subTotal,
            discount: discountAmount,
            deliveryFee,
            walletUsed: walletAmountUsed,
            finalAmount: finalAmount,
            totalOrderAmount: totalOrderAmount,
            taxAmount: 0,
            serviceCharge: 0,
            totalSavings: discountAmount + walletAmountUsed
          },

          // ✅ COUPON INFO SAVED
          couponInfo: couponCode ? {
            code: couponCode,
            discountApplied: discountAmount,
            appliedAt: now
          } : null,

          // ✅ DELIVERY INFO SAVED
          deliveryInfo: {
            address: deliveryAddress,
            estimatedDelivery: null,
            deliveryInstructions: deliveryAddress.instructions || null
          },

          // ✅ METADATA SAVED
          orderMetadata: {
            source: 'mobile_app',
            userAgent: null,
            ipAddress: null,
            referralCode: null
          }
        };

        transaction.set(orderRef, orderData);
        console.log('✅ Created orders document');

        // ─────────────────────────────────────────────────────────
        // DOCUMENT 3: deliveries collection
        // ─────────────────────────────────────────────────────────
        const deliveryRef = db.collection('deliveries').doc(deliveryId);
        transaction.set(deliveryRef, {
          deliveryId,
          orderId,
          userId,
          status: deliveryStatus,
          createdAt: now,
          updatedAt: now,
          deliveryDetails: {
            address: deliveryAddress,
            contactInfo: {
              name: deliveryAddress.name,
              phone: deliveryAddress.phoneNumber
            },
            locationInfo: {
              pincode: deliveryAddress.postalCode,
              city: deliveryAddress.city,
              state: deliveryAddress.state,
              country: deliveryAddress.country
            }
          },
          trackingInfo: {
            estimatedDelivery: null,
            actualDelivery: null,
            deliveryPartner: null,
            trackingNumber: null,
            deliveryAttempts: 0
          }
        });
        console.log('✅ Created deliveries document');
      });

      // ============================================================
      // 5. RETURN RESPONSE
      // ============================================================
      return {
        success: true,
        orderId,
        paymentId,
        deliveryId,
        amountBreakdown: {
          subTotal,
          discount: discountAmount,
          deliveryFee,
          walletUsed: walletAmountUsed,
          finalAmount,
          totalOrderAmount,
          totalSavings: discountAmount + walletAmountUsed
        },
        paymentInfo: {
          gateway,
          status: paymentStatus
        }
      };

    } catch (error) {
      console.error('Error creating order:', error);
      throw new Error(error instanceof Error ? 
                      error.message : 'Internal server error');
    }
  }
);
```

---

## STEP 4: Order Details Screen Displays Data
**File:** `lib/features/order/screens/order_details_screen.dart`

### What Data is Retrieved and Displayed:

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.exists) {
      final orderData = snapshot.data!.data() as Map<String, dynamic>;

      // ============================================================
      // EXTRACT DATA FROM FIRESTORE
      // ============================================================
      
      // Basic order info
      final orderId = orderData['orderId'];              // ✅ Available
      final status = orderData['status'];                // ✅ Available
      final createdAt = orderData['createdAt'] as Timestamp?;  // ✅ Available
      final paymentMode = orderData['paymentMode'];      // ✅ Available
      
      // Items
      final items = orderData['items'] as List<dynamic>? ?? [];
      // Each item has:
      // ✅ name, price, quantity, productImage
      // ❌ NO productId for linking
      // ❌ NO skuId for reference
      // ⚠️ selectedColor in deprecated field (not displayed)
      
      // Amount breakdown
      final amountBreakdown = orderData['amountBreakdown'] 
          as Map<String, dynamic>?;
      
      final subTotal = (amountBreakdown?['subTotal'] ?? 0).toDouble();
      final discount = (amountBreakdown?['discount'] ?? 0).toDouble();
      final deliveryFee = (amountBreakdown?['deliveryFee'] ?? 0).toDouble();
      final walletUsed = (amountBreakdown?['walletUsed'] ?? 0).toDouble();
      final finalAmount = (amountBreakdown?['finalAmount'] ?? 0).toDouble();
      final totalSavings = (amountBreakdown?['totalSavings'] ?? 0).toDouble();
      
      // ✅ ALL AMOUNTS AVAILABLE AND CORRECT
      
      // Coupon
      final couponInfo = orderData['couponInfo'] 
          as Map<String, dynamic>?;
      
      // Delivery
      final deliveryInfo = orderData['deliveryInfo'] 
          as Map<String, dynamic>?;
      final address = deliveryInfo?['address'] 
          as Map<String, dynamic>?;
      
      // ============================================================
      // DISPLAY DATA
      // ============================================================
      return CustomScrollView(
        slivers: [
          SliverAppBar(expandedHeight: 100, ...),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ✅ Order Status Card - Works
                _buildModernStatusCard(orderData, context),
                
                // ✅ Items Card - Partial
                _buildModernItemsCard(orderData, context),
                // Shows: Name, Qty, Price, Image
                // Missing: Variant details (color is in deprecated field)
                
                // ✅ Order Info Card - Works
                _buildModernOrderInfoCard(orderData, context),
                
                // ✅ Pricing Breakdown - FULLY WORKS
                _buildDetailedPricingBreakdown(context, orderData),
                // Shows:
                // ✅ Items Subtotal (₹200)
                // ✅ Coupon Discount (₹20)
                // ✅ Wallet Payment (₹50)
                // ✅ Delivery Fee (₹100)
                // ✅ Total Savings (₹70)
                // ✅ Final Amount (₹230)
                
                // ✅ Delivery Address Card - Works
                _buildModernAddressCard(orderData, context),
              ],
            ),
          ),
        ],
      );
    }
  },
)
```

### Pricing Breakdown Widget (FULLY WORKING):
```dart
Widget _buildDetailedPricingBreakdown(
    BuildContext context, Map<String, dynamic> orderData) {
  final amountBreakdown = orderData['amountBreakdown'] 
      as Map<String, dynamic>?;
  
  final subTotal = (amountBreakdown?['subTotal'] ?? 0).toDouble();
  final discount = (amountBreakdown?['discount'] ?? 0).toDouble();
  final deliveryFee = (amountBreakdown?['deliveryFee'] ?? 0).toDouble();
  final walletUsed = (amountBreakdown?['walletUsed'] ?? 0).toDouble();
  final finalAmount = (amountBreakdown?['finalAmount'] ?? 0).toDouble();
  final totalSavings = (amountBreakdown?['totalSavings'] ?? 0).toDouble();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Price Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Subtotal
        _buildDetailedPriceRow(context,
          'Items Subtotal',
          '₹${subTotal.toStringAsFixed(2)}',
          isSubtotal: true,
        ),
        
        // Discount
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _buildDetailedPriceRow(context,
            'Coupon Discount',
            '-₹${discount.toStringAsFixed(2)}',
            isDiscount: true,
          ),
        ],
        
        // Wallet
        if (walletUsed > 0) ...[
          const SizedBox(height: 8),
          _buildDetailedPriceRow(context,
            'Wallet Payment',
            '-₹${walletUsed.toStringAsFixed(2)}',
            isDiscount: true,
          ),
        ],
        
        // Delivery
        const SizedBox(height: 8),
        _buildDetailedPriceRow(context,
          'Delivery Fee',
          deliveryFee > 0 
            ? '₹${deliveryFee.toStringAsFixed(2)}'
            : 'FREE',
          isDelivery: true,
        ),
        
        const SizedBox(height: 12),
        Divider(height: 1),
        const SizedBox(height: 12),
        
        // Final Amount
        _buildDetailedPriceRow(context,
          'Total Amount Payable',
          '₹${finalAmount.toStringAsFixed(2)}',
          isTotal: true,
        ),
        
        // Total Savings
        if (totalSavings > 0) ...[
          const SizedBox(height: 8),
          _buildDetailedPriceRow(context,
            'Total Savings',
            '₹${totalSavings.toStringAsFixed(2)}',
            isSavings: true,
          ),
        ],
      ],
    ),
  );
}
```

---

## SUMMARY: What Gets Saved vs What's Displayed

| Data | Sent | Saved | Retrieved | Displayed |
|------|------|-------|-----------|-----------|
| **Order ID** | ✅ Gen | ✅ orders | ✅ | ✅ |
| **Item Name** | ✅ | ✅ | ✅ | ✅ |
| **Item Qty** | ✅ | ✅ | ✅ | ✅ |
| **Item Price** | ✅ | ✅ | ✅ | ✅ |
| **Item Image** | ✅ | ✅ | ✅ | ✅ |
| **SubTotal** | ✅ | ✅ | ✅ | ✅ |
| **Discount** | ✅ | ✅ | ✅ | ✅ |
| **Delivery Fee** | ✅ | ✅ | ✅ | ✅ |
| **Wallet Used** | ✅ | ✅ | ✅ | ✅ |
| **Final Amount** | ✅ | ✅ | ✅ | ✅ |
| **Coupon Code** | ✅ | ✅ | ✅ | ✅ |
| **Address** | ✅ | ✅ | ✅ | ✅ |
| **Product ID** | ❌ | ❌ | ❌ | — |
| **SKU ID** | ✅ (as productId) | ✅ | ✅ | ❌ (not shown) |
| **Selling Price** | ❌ | ❌ | ❌ | — |
| **Variant Attrs** | ⚠️ (Color only) | ⚠️ | ⚠️ | ❌ |

---

**Analysis Date:** February 1, 2026  
**Status:** Complete Code Review  
**Next Step:** Implement enhancements from guide
