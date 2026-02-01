# Order Details Screen Implementation Guide

## Overview
This guide shows how to implement the order details screen to display the comprehensive order data captured and stored in Firestore.

---

## 1. Fetch Order Data

### Basic Fetch Function
```dart
Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
  try {
    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();
    
    if (!orderDoc.exists) {
      throw Exception('Order not found');
    }
    
    return orderDoc.data() ?? {};
  } catch (e) {
    print('Error fetching order: $e');
    rethrow;
  }
}
```

---

## 2. Display Pricing Breakdown

### Widget: Pricing Breakdown Section
```dart
class PricingBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic> pricingSummary;
  final Map<String, dynamic>? couponInfo;

  const PricingBreakdownWidget({
    required this.pricingSummary,
    this.couponInfo,
  });

  @override
  Widget build(BuildContext context) {
    final orderSubtotal = pricingSummary['orderSubtotal'] as double? ?? 0;
    final productDiscount = pricingSummary['productDiscount'] as double? ?? 0;
    final couponDiscount = pricingSummary['couponDiscount'] as double? ?? 0;
    final totalDiscount = pricingSummary['totalDiscount'] as double? ?? 0;
    final subtotalAfterDiscount = pricingSummary['subtotalAfterDiscount'] as double? ?? 0;
    final deliveryFee = pricingSummary['deliveryFee'] as double? ?? 0;
    final totalBeforePayment = pricingSummary['totalBeforePayment'] as double? ?? 0;
    final couponCode = pricingSummary['couponCode'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Product Subtotal
            _buildPricingRow(
              label: 'Product Subtotal',
              amount: orderSubtotal,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Product Discount
            if (productDiscount > 0)
              _buildPricingRow(
                label: '- Product Discount',
                amount: productDiscount,
                style: TextStyle(fontSize: 14, color: Colors.green),
              ),
            // Coupon Discount
            if (couponCode != null && couponDiscount > 0) ...[
              const SizedBox(height: 8),
              _buildPricingRow(
                label: '- Coupon (${couponCode ?? ''})',
                amount: couponDiscount,
                style: TextStyle(fontSize: 14, color: Colors.green),
              ),
            ],
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            // Subtotal After Discount
            _buildPricingRow(
              label: 'Subtotal After Discount',
              amount: subtotalAfterDiscount,
              isBold: true,
            ),
            const SizedBox(height: 8),
            // Delivery Fee
            _buildPricingRow(
              label: '+ Delivery Fee',
              amount: deliveryFee,
              style: TextStyle(fontSize: 14),
            ),
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            // Total
            _buildPricingRow(
              label: 'Order Total',
              amount: totalBeforePayment,
              isBold: true,
              fontSize: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow({
    required String label,
    required double amount,
    TextStyle? style,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (style ?? TextStyle()).copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: (style ?? TextStyle()).copyWith(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
```

---

## 3. Display Payment Breakdown

### Widget: Payment Summary Section
```dart
class PaymentSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> paymentSummary;
  final Map<String, dynamic>? walletInfo;

  const PaymentSummaryWidget({
    required this.paymentSummary,
    this.walletInfo,
  });

  @override
  Widget build(BuildContext context) {
    final paymentMode = paymentSummary['paymentMode'] as String? ?? 'unknown';
    final walletPaidAmount = paymentSummary['walletPaidAmount'] as double? ?? 0;
    final onlinePaidAmount = paymentSummary['onlinePaidAmount'] as double? ?? 0;
    final totalOrderValue = paymentSummary['totalOrderValue'] as double? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // Payment Mode
            _buildPaymentRow(
              label: 'Payment Method',
              value: _getPaymentModeLabel(paymentMode),
            ),
            const SizedBox(height: 12),
            // Payment Split
            if (paymentMode == 'partial_wallet') ...[
              _buildPaymentRow(
                label: 'Wallet Payment',
                amount: walletPaidAmount,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildPaymentRow(
                label: 'Online Payment (Razorpay)',
                amount: onlinePaidAmount,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              Divider(),
              const SizedBox(height: 8),
              _buildPaymentRow(
                label: 'Total Amount Paid',
                amount: totalOrderValue,
                isBold: true,
              ),
            ] else if (paymentMode == 'wallet') ...[
              _buildPaymentRow(
                label: 'Paid from Wallet',
                amount: walletPaidAmount,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Divider(),
              const SizedBox(height: 8),
              _buildPaymentRow(
                label: 'Total Amount Paid',
                amount: totalOrderValue,
                isBold: true,
              ),
            ] else if (paymentMode == 'cod') ...[
              _buildPaymentRow(
                label: 'To Be Paid at Delivery',
                amount: totalOrderValue,
                color: Colors.orange,
              ),
            ] else ...[
              // razorpay
              _buildPaymentRow(
                label: 'Paid via Razorpay',
                amount: onlinePaidAmount,
                color: Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow({
    required String label,
    String? value,
    double? amount,
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        if (value != null)
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          )
        else if (amount != null)
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
      ],
    );
  }

  String _getPaymentModeLabel(String mode) {
    switch (mode) {
      case 'razorpay':
        return 'Credit/Debit Card / UPI';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Wallet';
      case 'partial_wallet':
        return 'Wallet + Online';
      default:
        return mode;
    }
  }
}
```

---

## 4. Display Order Items

### Widget: Order Items List
```dart
class OrderItemsWidget extends StatelessWidget {
  final List<dynamic> items;

  const OrderItemsWidget({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${items.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                return _buildItemCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final productId = item['productId'] as String?;
    final skuId = item['skuId'] as String?;
    final name = item['name'] as String?;
    final quantity = item['quantity'] as int? ?? 1;
    final productBasePrice = item['productBasePrice'] as double? ?? 0;
    final productCurrentPrice = item['productCurrentPrice'] as double? ?? 0;
    final itemSubtotal = item['itemSubtotal'] as double? ?? 0;
    final itemDiscount = item['itemDiscount'] as double? ?? 0;
    final variants = item['variants'] as Map<String, dynamic>?;
    final category = item['category'] as String?;
    final brand = item['brand'] as String?;
    final productImage = item['productImage'] as String?;

    final hasDiscount = itemDiscount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item Image and Basic Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            if (productImage != null && productImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  productImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported),
                    );
                  },
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: Icon(Icons.image_not_supported),
              ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? 'Unknown Product',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (brand != null || category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${category ?? 'Product'} • ${brand ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${skuId ?? productId ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Variants
        if (variants != null && variants.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: variants.entries.map((entry) {
              return Chip(
                label: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(fontSize: 11),
                ),
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        // Pricing Details
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MRP and Current Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MRP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${productBasePrice.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Selling Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selling Price',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '₹${productCurrentPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${quantity} unit${quantity > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '- ₹${itemDiscount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              Divider(height: 12),
              // Item Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${itemSubtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

## 5. Complete Order Details Screen

### Main Screen Widget
```dart
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrderDetails();
  }

  Future<Map<String, dynamic>> _fetchOrderDetails() async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      return orderDoc.data() ?? {};
    } catch (e) {
      print('Error fetching order: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text('Error loading order'),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final orderData = snapshot.data ?? {};
          final items = orderData['items'] as List? ?? [];
          final pricingSummary = orderData['pricingSummary'] as Map<String, dynamic>? ?? {};
          final paymentSummary = orderData['paymentSummary'] as Map<String, dynamic>? ?? {};
          final couponInfo = orderData['couponInfo'] as Map<String, dynamic>?;
          final walletInfo = orderData.containsKey('walletInfo') 
              ? orderData['walletInfo'] as Map<String, dynamic>?
              : null;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID and Status
                  _buildOrderHeader(context, orderData),
                  const SizedBox(height: 20),

                  // Order Items
                  if (items.isNotEmpty)
                    OrderItemsWidget(items: items),
                  const SizedBox(height: 20),

                  // Pricing Breakdown
                  PricingBreakdownWidget(
                    pricingSummary: pricingSummary,
                    couponInfo: couponInfo,
                  ),
                  const SizedBox(height: 20),

                  // Payment Summary
                  PaymentSummaryWidget(
                    paymentSummary: paymentSummary,
                    walletInfo: walletInfo,
                  ),
                  const SizedBox(height: 20),

                  // Delivery Address
                  if (orderData.containsKey('deliveryInfo'))
                    _buildDeliverySection(context, orderData['deliveryInfo']),
                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, Map<String, dynamic> orderData) {
    final orderId = orderData['orderId'] as String?;
    final status = orderData['status'] as String?;
    final createdAt = orderData['createdAt'] as Timestamp?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId?.substring(orderId.length - 8) ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              createdAt != null
                  ? 'Ordered on ${DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())}'
                  : 'Order Date: N/A',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection(BuildContext context, Map<String, dynamic> deliveryInfo) {
    final address = deliveryInfo['address'] as Map<String, dynamic>?;

    if (address == null) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              address['name'] ?? 'Unknown',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(address['phoneNumber'] ?? 'N/A'),
            const SizedBox(height: 8),
            Text(address['street'] ?? ''),
            Text('${address['city'] ?? ''}, ${address['state'] ?? ''} ${address['postalCode'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Share order details
            Share.share('Check out my order: ${widget.orderId}');
          },
          icon: Icon(Icons.share),
          label: Text('Share'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Download invoice
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invoice download coming soon')),
            );
          },
          icon: Icon(Icons.download),
          label: Text('Invoice'),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'processing_payment':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green[700] ?? Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'processing_payment':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      default:
        return status ?? 'Unknown';
    }
  }
}
```

---

## 6. Usage Example

```dart
// Navigate to order details screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OrderDetailsScreen(
      orderId: 'ORD1234567890',
    ),
  ),
);
```

---

## 7. Required Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^4.14.0
  intl: ^0.19.0
  share_plus: ^7.2.0  # For share functionality
```

---

## 8. Data Flow

```
Order Details Screen
        ↓
   Fetch from Firestore
        ↓
        ├─→ orders/{orderId}
        │   ├─ items []
        │   ├─ pricingSummary {}
        │   ├─ paymentSummary {}
        │   ├─ couponInfo {}
        │   └─ deliveryInfo {}
        ↓
Display Components
        ├─ Order Header (ID, Status, Date)
        ├─ Order Items Widget
        ├─ Pricing Breakdown Widget
        ├─ Payment Summary Widget
        └─ Delivery Address Widget
```

---

## 9. Testing the Implementation

### Test Data Structure
```json
{
  "orderId": "ORD1234567890",
  "userId": "user123",
  "status": "confirmed",
  "items": [
    {
      "productId": "PAPER-A4",
      "skuId": "SKU-BLUE-100",
      "name": "A4 Paper Ream",
      "quantity": 1,
      "productBasePrice": 100,
      "productCurrentPrice": 90,
      "itemSubtotal": 90,
      "itemDiscount": 10,
      "variants": {"color": "Blue"},
      "category": "Paper",
      "brand": "Premium",
      "productImage": "https://..."
    }
  ],
  "pricingSummary": {
    "orderSubtotal": 190,
    "productDiscount": 0,
    "couponCode": "SAVE50",
    "couponDiscount": 30,
    "totalDiscount": 30,
    "subtotalAfterDiscount": 160,
    "deliveryFee": 50,
    "totalBeforePayment": 210
  },
  "paymentSummary": {
    "paymentMode": "partial_wallet",
    "walletPaidAmount": 80,
    "onlinePaidAmount": 130,
    "totalOrderValue": 210
  },
  "couponInfo": {
    "code": "SAVE50",
    "discountApplied": 30,
    "appliedAt": "2024-01-15T10:30:00Z"
  },
  "deliveryInfo": {
    "address": {
      "name": "John Doe",
      "phoneNumber": "9876543210",
      "street": "123 Main Street",
      "city": "Jaipur",
      "state": "Rajasthan",
      "postalCode": "302001",
      "country": "India"
    }
  }
}
```

---

## 10. Key Points to Remember

1. **All amounts are in rupees (₹)** - No conversion needed from Firebase
2. **Payment Summary always sums to Total** - `walletPaidAmount + onlinePaidAmount = totalOrderValue`
3. **Pricing always accumulates correctly** - `subtotalAfterDiscount + deliveryFee = totalBeforePayment`
4. **Item discount is per item** - Already multiplied by quantity
5. **Variant information is in object format** - Not as comma-separated string
6. **SKU ID is separate from Product ID** - Use SKU for order items reference
7. **All data is immutable after order creation** - These are final calculated values

