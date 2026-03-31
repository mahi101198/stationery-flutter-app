import { onCall, onRequest } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import * as crypto from 'crypto';

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Razorpay configuration - loaded lazily
let razorpayConfig: {
  keyId: string;
  keySecret: string;
  webhookSecret: string;
} | null = null;

// Initialize configuration from environment variables
function getConfig() {
  if (razorpayConfig) return razorpayConfig;

  // Load from environment variables
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

  // Validate that all required environment variables are set
  if (!keyId || !keySecret || !webhookSecret) {
    console.error('❌ Missing required Razorpay environment variables:', {
      keyId: keyId ? 'SET' : 'NOT_SET',
      keySecret: keySecret ? 'SET' : 'NOT_SET',
      webhookSecret: webhookSecret ? 'SET' : 'NOT_SET'
    });
    throw new Error('Missing required Razorpay environment variables. Please set RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, and RAZORPAY_WEBHOOK_SECRET as environment variables.');
  }

  razorpayConfig = {
    keyId,
    keySecret,
    webhookSecret
  };

  // Log configuration for debugging (without exposing secrets)
  console.log('🔧 Razorpay Configuration loaded:', {
    keyId: `${keyId.substring(0, 8)}...`,
    keySecret: 'SET',
    webhookSecret: 'SET'
  });

  return razorpayConfig;
}



/**
 * Create order with comprehensive data tracking
 * This function handles 4 payment modes: razorpay, cod, wallet, partial_wallet
 * 
 * Required Payload Structure:
 * {
 *   items: Array<{productId, skuId, name, price, quantity, productImage?, category?, brand?, productBasePrice?, productCurrentPrice?, itemSubtotal?, itemDiscount?, variants?}>,
 *   pricingSummary: {orderSubtotal, productDiscount, couponCode, couponDiscount, totalDiscount, subtotalAfterDiscount, deliveryFee, totalBeforePayment},
 *   paymentSummary: {paymentMode, walletPaidAmount, onlinePaidAmount, totalOrderValue},
 *   paymentMode: 'razorpay'|'cod'|'wallet'|'partial_wallet',
 *   deliveryAddress: {id, name, phoneNumber, street, city, state, postalCode, country},
 *   paymentDetails?: {gateway, transactionId?, status?},
 *   currency?: string (default: 'INR')
 * }
 */
export const createOrder = onCall(
  { cors: true },
  async (request) => {
    try {
      console.log('🔍 Firebase Function: createOrder called');

      if (!request.auth) {
        throw new Error('Unauthorized');
      }

      const userId = request.auth.uid;

      // Extract data from comprehensive payload
      const {
        items,
        pricingSummary,          // Pricing breakdown: orderSubtotal, productDiscount, couponCode, couponDiscount, totalDiscount, subtotalAfterDiscount, deliveryFee, totalBeforePayment
        paymentSummary,          // Payment breakdown: paymentMode, walletPaidAmount, onlinePaidAmount, totalOrderValue
        paymentMode,
        deliveryAddress,
        paymentDetails,          // Payment details object
        currency = 'INR'
      } = request.data;

      // Comprehensive validation
      if (!items || !Array.isArray(items) || items.length === 0) {
        throw new Error('Items array is required');
      }
      if (!paymentMode) {
        throw new Error('Payment mode is required');
      }
      if (!deliveryAddress) {
        throw new Error('Delivery address is required');
      }

      // Validate delivery address format
      if (!deliveryAddress.name || !deliveryAddress.phoneNumber || !deliveryAddress.street ||
        !deliveryAddress.city || !deliveryAddress.state || !deliveryAddress.postalCode || !deliveryAddress.country) {
        throw new Error('Delivery address must include: name, phoneNumber, street, city, state, postalCode, country');
      }
      if (!pricingSummary) {
        throw new Error('pricingSummary is required');
      }
      if (!paymentSummary) {
        throw new Error('paymentSummary is required');
      }

      // Extract pricing summary (properly named fields)
      const orderSubtotal = pricingSummary.orderSubtotal || 0;
      const productDiscount = pricingSummary.productDiscount || 0;
      const couponCode = pricingSummary.couponCode || null;
      const couponDiscount = pricingSummary.couponDiscount || 0;
      const totalDiscount = pricingSummary.totalDiscount || 0;
      const subtotalAfterDiscount = pricingSummary.subtotalAfterDiscount || 0;
      const deliveryFee = pricingSummary.deliveryFee || 0;
      const totalBeforePayment = pricingSummary.totalBeforePayment || 0;

      // Extract payment summary (properly named fields)
      const walletPaidAmount = paymentSummary.walletPaidAmount || 0;
      const onlinePaidAmount = paymentSummary.onlinePaidAmount || 0;
      const totalOrderValue = paymentSummary.totalOrderValue || 0;

      // For backward compatibility, calculate these variables
      const discountAmount = totalDiscount;
      const walletAmountUsed = walletPaidAmount;
      const finalAmount = onlinePaidAmount;

      // Validate pricing amounts
      if (orderSubtotal <= 0) {
        throw new Error('Order subtotal must be greater than 0');
      }
      if (totalDiscount < 0) {
        throw new Error('Total discount cannot be negative');
      }
      if (deliveryFee < 0) {
        throw new Error('Delivery fee cannot be negative');
      }
      if (totalOrderValue <= 0) {
        throw new Error('Total order value must be greater than 0');
      }

      // ✅ VALIDATE PRICING FORMULAS (MRP-based, no double-counting)
      // Validate that subtotalAfterDiscount is calculated correctly
      const expectedSubtotalAfterDiscount = orderSubtotal - totalDiscount;
      if (Math.abs(subtotalAfterDiscount - expectedSubtotalAfterDiscount) > 0.01) {
        throw new Error(`subtotalAfterDiscount calculation error: expected ${expectedSubtotalAfterDiscount}, got ${subtotalAfterDiscount}`);
      }

      // Validate that totalBeforePayment is calculated correctly
      const expectedTotalBeforePayment = subtotalAfterDiscount + deliveryFee;
      if (Math.abs(totalBeforePayment - expectedTotalBeforePayment) > 0.01) {
        throw new Error(`totalBeforePayment calculation error: expected ${expectedTotalBeforePayment}, got ${totalBeforePayment}`);
      }

      // Validate that totalOrderValue matches totalBeforePayment
      if (Math.abs(totalOrderValue - totalBeforePayment) > 0.01) {
        throw new Error(`totalOrderValue does not match totalBeforePayment: ${totalOrderValue} vs ${totalBeforePayment}`);
      }

      // Validate that productDiscount + couponDiscount = totalDiscount
      const expectedTotalDiscount = productDiscount + couponDiscount;
      if (Math.abs(totalDiscount - expectedTotalDiscount) > 0.01) {
        throw new Error(`totalDiscount calculation error: productDiscount(${productDiscount}) + couponDiscount(${couponDiscount}) = ${expectedTotalDiscount}, but got ${totalDiscount}`);
      }

      console.log('✅ Pricing formula validation passed');
      console.log('🔍 Creating order for user:', userId);

      // Validate payment amounts
      if (walletPaidAmount < 0) {
        throw new Error('Wallet paid amount cannot be negative');
      }
      if (onlinePaidAmount < 0) {
        throw new Error('Online paid amount cannot be negative');
      }

      // Validate payment mode consistency
      if (paymentMode === 'wallet' && walletPaidAmount <= 0) {
        throw new Error('Wallet amount must be positive for wallet payment mode');
      }
      if (paymentMode === 'wallet' && onlinePaidAmount !== 0) {
        throw new Error('Online amount must be 0 for wallet-only payment');
      }
      if (paymentMode === 'cod' && walletPaidAmount !== 0) {
        throw new Error('Wallet amount must be 0 for COD payment');
      }

      // Validate partial wallet payments
      if (paymentMode === 'partial_wallet') {
        if (walletPaidAmount <= 0) {
          throw new Error('Valid wallet amount is required for partial wallet payment');
        }
        if (onlinePaidAmount <= 0) {
          throw new Error('Valid online amount is required for partial wallet payment');
        }
        const expectedTotal = walletPaidAmount + onlinePaidAmount;
        if (Math.abs(totalOrderValue - expectedTotal) > 0.01) {
          throw new Error(`Total order value (${totalOrderValue}) does not match wallet (${walletPaidAmount}) + online (${onlinePaidAmount}) = ${expectedTotal}`);
        }
      }

      // Validate Razorpay and COD modes have correct amounts
      if ((paymentMode === 'razorpay' || paymentMode === 'cod') && walletPaidAmount !== 0) {
        throw new Error(`Wallet amount must be 0 for ${paymentMode} payment`);
      }

      // Generate IDs
      const orderId = `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const paymentId = `PAY${Date.now()}${Math.floor(Math.random() * 1000)}`;
      const deliveryId = `DEL${Date.now()}${Math.floor(Math.random() * 1000)}`;

      // Determine payment mode flags and statuses (outside transaction for scope)
      const isWalletFull = paymentMode === 'wallet';
      const isWalletPartial = paymentMode === 'partial_wallet';
      const isOnline = paymentMode === 'razorpay';
      const isCOD = paymentMode === 'cod';

      // Calculate statuses (partial_wallet uses same flow as razorpay)
      const orderStatus = isCOD ? 'confirmed' :
        isWalletFull ? 'confirmed' :
          'processing_payment'; // Both razorpay and partial_wallet
      const paymentStatus = isCOD ? 'pending_collection' :
        isWalletFull ? 'paid' :
          'created'; // Both razorpay and partial_wallet
      const deliveryStatus = isCOD ? 'pending_dispatch' :
        isWalletFull ? 'pending_dispatch' :
          'pending'; // Both razorpay and partial_wallet
      const gateway = isCOD ? 'cod' :
        isWalletFull ? 'wallet' :
          'razorpay'; // Both razorpay and partial_wallet use razorpay

      // Handle different payment modes using internal methods
      let razorpayOrderId = null;

      // Map payment modes to internal methods
      switch (paymentMode) {
        case 'razorpay':
          razorpayOrderId = await handleRazorpayPayment(orderId, userId, paymentId, finalAmount, currency);
          break;
        case 'cod':
          await handleCODPayment(orderId, userId, paymentId, finalAmount, currency);
          break;
        case 'wallet':
          await handleWalletPayment(orderId, userId, paymentId, finalAmount, currency, walletAmountUsed);
          break;
        case 'partial_wallet':
          razorpayOrderId = await handlePartialWalletPayment(orderId, userId, paymentId, totalOrderValue, currency, walletAmountUsed);
          break;
        default:
          throw new Error(`Invalid payment mode: ${paymentMode}. Supported modes: razorpay, cod, wallet, partial_wallet`);
      }

      // 2. Create Firestore documents in a transaction
      await db.runTransaction(async (transaction) => {
        const now = new Date();

        // Use pre-calculated statuses

        console.log('🔍 Creating documents with statuses:', {
          orderStatus,
          paymentStatus,
          deliveryStatus,
          gateway
        });

        // 2.0. Deduct wallet amount for wallet payments (before creating other documents)
        if (isWalletFull || isWalletPartial) {
          const userRef = db.collection('users').doc(userId);
          transaction.update(userRef, {
            walletBalance: FieldValue.increment(-walletAmountUsed),
            updatedAt: now,
          });
          console.log('💰 Deducted ₹' + walletAmountUsed + ' from user wallet');
        }

        // 2a. Create razorpay_orders document (for Razorpay and Partial Wallet modes)
        if ((paymentMode === 'razorpay' || paymentMode === 'partial_wallet') && razorpayOrderId) {
          const razorpayOrderRef = db.collection('razorpay_orders').doc(razorpayOrderId);

          // Calculate amount for razorpay_orders
          // For razorpay: use onlinePaidAmount
          // For partial_wallet: use onlinePaidAmount (already the remaining after wallet deduction)
          const razorpayAmount = Math.round(onlinePaidAmount * 100);

          transaction.set(razorpayOrderRef, {
            razorpayOrderId,
            userId,
            amount: razorpayAmount,
            currency,
            status: 'created',
            createdAt: now,
            orderId,
            paymentId,
            deliveryId,
            // Additional fields for partial wallet
            isPartialWalletPayment: paymentMode === 'partial_wallet',
            walletAmount: paymentMode === 'partial_wallet' ? walletPaidAmount : null,
            totalAmount: paymentMode === 'partial_wallet' ? totalOrderValue : null,
          });
          console.log('✅ Created razorpay_orders document for', paymentMode);
        } else {
          console.log('⏭️ Skipping razorpay_orders document (COD/Wallet mode)');
        }

        // 2b. Create comprehensive payments document
        const paymentRef = db.collection('payments').doc(paymentId);
        const paymentData: any = {
          paymentId,
          orderId,
          userId,
          method: paymentMode,
          currency,
          status: paymentStatus,
          gateway,
          createdAt: now,
          updatedAt: now,

          // Pricing breakdown with proper field names
          pricingSummary: {
            orderSubtotal,
            productDiscount,
            couponCode,
            couponDiscount,
            totalDiscount,
            subtotalAfterDiscount,
            deliveryFee,
            totalBeforePayment
          },

          // Payment breakdown with proper field names
          paymentSummary: {
            paymentMode,
            walletPaidAmount,
            onlinePaidAmount,
            totalOrderValue
          },

          // Payment details (from payload or defaults)
          paymentDetails: {
            gateway: paymentDetails?.gateway || gateway,
            transactionId: paymentDetails?.transactionId || null,
            status: paymentDetails?.status || paymentStatus,
            ...paymentDetails
          },

          // Coupon information
          couponInfo: couponCode ? {
            code: couponCode,
            discountApplied: couponDiscount,
            appliedAt: now
          } : null,

          // Wallet information
          walletInfo: (isWalletFull || isWalletPartial) ? {
            amountUsed: walletPaidAmount,
            isPartialPayment: isWalletPartial,
            remainingAmount: isWalletPartial ? onlinePaidAmount : 0,
            paymentMethod: isWalletPartial ? 'razorpay' : null // Partial wallet uses Razorpay for remaining
          } : null
        };

        // Add razorpayOrderId for Razorpay and Partial Wallet payments
        if ((isOnline || isWalletPartial) && razorpayOrderId) {
          paymentData.razorpayOrderId = razorpayOrderId;
        }

        transaction.set(paymentRef, paymentData);
        console.log('✅ Created payments document');

        // 2c. Create comprehensive orders document
        const orderRef = db.collection('orders').doc(orderId);
        const orderData: any = {
          orderId,
          userId,
          paymentMode,
          paymentId,
          deliveryId,
          status: orderStatus,
          createdAt: now,
          updatedAt: now,

          // Comprehensive item details with all product information
          items: items.map((item: any) => ({
            // Basic product information
            productId: item.productId,
            skuId: item.skuId || item.productId, // ✅ SKU ID separate from Product ID
            name: item.name,
            quantity: item.quantity,
            productImage: item.productImage || null,

            // Pricing information (MRP-based, correct fields)
            productBasePrice: item.productBasePrice || item.price, // ✅ MRP (base price)
            productCurrentPrice: item.productCurrentPrice || item.price, // ✅ SKU selling price
            itemSubtotalAtMRP: item.itemSubtotalAtMRP || (item.productBasePrice || item.price) * item.quantity, // ✅ Base price × Quantity
            itemSubtotalAtSellingPrice: item.itemSubtotalAtSellingPrice || (item.productCurrentPrice || item.price) * item.quantity, // ✅ Selling price × Quantity
            itemAutoDiscount: item.itemAutoDiscount || 0, // ✅ Discount per item (MRP - selling)

            // Product metadata
            category: item.category || null,
            brand: item.brand || null,

            // Variant information (color, size, etc.)
            variants: item.variants || null,
            selectedColor: item.selectedColor || null, // ✅ For backward compatibility

            // Additional metadata for reference
            itemMetadata: {
              basePriceUsed: item.productBasePrice || item.price,
              currentPriceUsed: item.productCurrentPrice || item.price,
              discountPerItem: item.itemAutoDiscount || 0,
              calculatedAt: now.toISOString()
            }
          })),

          // Comprehensive pricing breakdown with CORRECT field names (MRP-based, no double-counting)
          pricingSummary: {
            orderSubtotal,             // ✅ Sum of all itemSubtotalAtMRP (base prices)
            productDiscount,           // ✅ Auto discount from price difference
            couponCode,                // ✅ Coupon code applied (if any)
            couponDiscount,            // ✅ Discount amount from coupon
            totalDiscount,             // ✅ Sum of all discounts (deducted ONCE)
            subtotalAfterDiscount,     // ✅ Order amount after all discounts
            deliveryFee,               // ✅ Shipping/delivery charge
            totalBeforePayment,        // ✅ Final amount before payment mode split
          },

          // Comprehensive payment breakdown
          paymentSummary: {
            paymentMode,               // Payment method: razorpay, cod, wallet, partial_wallet
            walletPaidAmount,          // Amount paid from wallet
            onlinePaidAmount,          // Amount paid online (Razorpay/COD)
            totalOrderValue,           // Grand total of the order
          },

          // Coupon information
          couponInfo: couponCode ? {
            code: couponCode,
            discountApplied: discountAmount,
            appliedAt: now
          } : null,

          // Delivery information
          deliveryInfo: {
            address: deliveryAddress,
            estimatedDelivery: null, // Can be calculated later
            deliveryInstructions: deliveryAddress.instructions || null
          },

          // Order metadata
          orderMetadata: {
            source: 'mobile_app', // Can be dynamic
            userAgent: null, // Can be added if needed
            ipAddress: null, // Can be added if needed
            referralCode: null // Can be added if needed
          }
        };

        // Add razorpayOrderId for Razorpay and Partial Wallet payments
        if ((isOnline || isWalletPartial) && razorpayOrderId) {
          orderData.razorpayOrderId = razorpayOrderId;
        }

        transaction.set(orderRef, orderData);
        console.log('✅ Created orders document');

        // 2d. Create comprehensive deliveries document
        const deliveryRef = db.collection('deliveries').doc(deliveryId);
        transaction.set(deliveryRef, {
          deliveryId,
          orderId,
          userId,
          status: deliveryStatus,
          createdAt: now,
          updatedAt: now,

          // Comprehensive delivery information
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
              country: deliveryAddress.country,
              street: deliveryAddress.street,
              coordinates: deliveryAddress.coordinates || null
            },
            deliveryInstructions: deliveryAddress.instructions || null,
            preferredDeliveryTime: deliveryAddress.preferredTime || null
          },

          // Delivery tracking
          trackingInfo: {
            estimatedDelivery: null, // Will be calculated later
            actualDelivery: null,
            deliveryPartner: null,
            trackingNumber: null,
            deliveryAttempts: 0
          }
        });
        console.log('✅ Created deliveries document');

        console.log('✅ All Firestore documents created successfully');
      });

      // 3. Send FCM notification based on payment mode
      if (isCOD) {
        console.log('📲 Sending COD order confirmation notification');
        await sendOrderNotification(userId, orderId, 'cod_order_placed');
      } else if (isWalletFull) {
        console.log('📲 Sending Wallet payment confirmation notification');
        await sendOrderNotification(userId, orderId, 'wallet_order_placed');
      } else if (isOnline || isWalletPartial) {
        // Both Razorpay and Partial Wallet use the same flow - notification after webhook
        console.log('⏳ Payment: Will send notification after webhook confirmation');
      }

      // 4. Return comprehensive response
      const response: any = {
        success: true,
        orderId,
        paymentId,
        deliveryId,
        currency,
        paymentMode,

        // Pricing breakdown with proper field names
        pricingSummary: {
          orderSubtotal,
          productDiscount,
          couponCode,
          couponDiscount,
          totalDiscount,
          subtotalAfterDiscount,
          deliveryFee,
          totalBeforePayment
        },

        // Payment breakdown with proper field names
        paymentSummary: {
          paymentMode,
          walletPaidAmount,
          onlinePaidAmount,
          totalOrderValue
        },

        // Payment information
        paymentInfo: {
          gateway,
          status: paymentStatus,
          razorpayOrderId: razorpayOrderId || null
        },

        // Coupon information
        couponInfo: couponCode ? {
          code: couponCode,
          discountApplied: couponDiscount
        } : null,

        // Wallet information
        walletInfo: (isWalletFull || isWalletPartial) ? {
          amountUsed: walletPaidAmount,
          isPartialPayment: isWalletPartial,
          remainingAmount: isWalletPartial ? onlinePaidAmount : 0,
          paymentMethod: isWalletPartial ? 'razorpay' : null
        } : null,

        // Order status
        orderStatus: {
          status: orderStatus,
          paymentStatus,
          deliveryStatus
        },

        // Timestamps
        timestamps: {
          createdAt: new Date().toISOString(),
          estimatedDelivery: null // Can be calculated later
        }
      };

      console.log('✅ createOrder completed successfully');
      return response;

    } catch (error) {
      console.error('Error creating order:', error);
      throw new Error(error instanceof Error ? error.message : 'Internal server error');
    }
  }
);

// =============================================================================
// INTERNAL PAYMENT METHODS
// =============================================================================

/**
 * Handle Razorpay payment - creates Razorpay order via API
 */
async function handleRazorpayPayment(orderId: string, userId: string, paymentId: string, amount: number, currency: string): Promise<string> {
  console.log('💳 RAZORPAY MODE: Creating Razorpay order via API');

  const razorpayOrderData = {
    amount: Math.round(amount * 100), // Convert to paise
    currency,
    receipt: `receipt_${orderId}`,
    notes: {
      orderId,
      userId,
      paymentId,
      timestamp: new Date().toISOString(),
    },
  };

  console.log('🔍 Razorpay order data:', razorpayOrderData);

  const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${Buffer.from(`${getConfig().keyId}:${getConfig().keySecret}`).toString('base64')}`,
    },
    body: JSON.stringify(razorpayOrderData),
  });

  if (!razorpayResponse.ok) {
    const error = await razorpayResponse.text();
    console.error('Razorpay API error:', error);
    throw new Error('Failed to create Razorpay order');
  }

  const razorpayOrder = await razorpayResponse.json();
  console.log('✅ Razorpay order created:', razorpayOrder.id);

  return razorpayOrder.id;
}

/**
 * Handle COD payment - no external API calls needed
 */
async function handleCODPayment(orderId: string, userId: string, paymentId: string, amount: number, currency: string): Promise<void> {
  console.log('💵 COD MODE: Creating COD order directly');
  // COD doesn't require any external API calls
  // All processing happens in Firestore transaction
}

/**
 * Handle full wallet payment - validates wallet amount
 */
async function handleWalletPayment(orderId: string, userId: string, paymentId: string, amount: number, currency: string, walletAmount: number): Promise<void> {
  console.log('💰 WALLET MODE: Creating full wallet payment order');
  console.log('💰 Wallet amount:', walletAmount);

  // Validate wallet amount
  if (!walletAmount || walletAmount <= 0) {
    throw new Error('Valid wallet amount is required for wallet payment');
  }
  if (walletAmount !== amount) {
    throw new Error('Wallet amount must match order amount for full wallet payment');
  }

  // Full wallet payment doesn't require external API calls
  // All processing happens in Firestore transaction
}

/**
 * Handle partial wallet payment - validates wallet amount and uses Razorpay flow for remaining amount
 */
async function handlePartialWalletPayment(orderId: string, userId: string, paymentId: string, amount: number, currency: string, walletAmount: number): Promise<string> {
  console.log('💰 PARTIAL WALLET MODE: Using Razorpay flow for remaining amount');
  console.log('💰 Wallet amount:', walletAmount);
  console.log('💰 Total amount:', amount);

  // Validate wallet amount
  if (!walletAmount || walletAmount <= 0) {
    throw new Error('Valid wallet amount is required for partial wallet payment');
  }
  if (walletAmount >= amount) {
    throw new Error('Wallet amount must be less than total amount for partial payment');
  }

  const remainingAmount = amount - walletAmount;
  console.log('💰 Remaining amount to be paid via Razorpay:', remainingAmount);

  // Use the same Razorpay flow but with remaining amount and partial wallet notes
  const razorpayOrderData = {
    amount: Math.round(remainingAmount * 100), // Convert to paise
    currency,
    receipt: `receipt_${orderId}`,
    notes: {
      orderId,
      userId,
      paymentId,
      isPartialWalletPayment: true,
      walletAmount,
      totalAmount: amount,
      timestamp: new Date().toISOString(),
    },
  };

  console.log('🔍 Creating Razorpay order for partial wallet payment:', razorpayOrderData);

  const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${Buffer.from(`${getConfig().keyId}:${getConfig().keySecret}`).toString('base64')}`,
    },
    body: JSON.stringify(razorpayOrderData),
  });

  if (!razorpayResponse.ok) {
    const error = await razorpayResponse.text();
    console.error('Razorpay API error for partial wallet payment:', error);
    throw new Error('Failed to create Razorpay order for remaining payment');
  }

  const razorpayOrder = await razorpayResponse.json();
  console.log('✅ Razorpay order created for partial wallet payment:', razorpayOrder.id);

  return razorpayOrder.id;
}


/**
 * Razorpay webhook handler
 * CRITICAL: Responds immediately to Razorpay to avoid timeout, then processes asynchronously
 */
export const razorpayWebhook = onRequest(
  {
    cors: true,
    timeoutSeconds: 60,  // Extended timeout for processing
    memory: '256MiB'     // Adequate memory for processing
  },
  async (req, res) => {
    try {
      const signature = req.headers['x-razorpay-signature'] as string;
      const body = JSON.stringify(req.body);

      // Verify webhook signature using webhook secret (not API key secret)
      const expectedSignature = crypto
        .createHmac('sha256', getConfig().webhookSecret)
        .update(body)
        .digest('hex');

      if (signature !== expectedSignature) {
        console.error('Invalid webhook signature');
        res.status(400).json({ error: 'Invalid signature' });
        return;
      }

      const event = req.body;

      // ⚡ RESPOND IMMEDIATELY to Razorpay to avoid timeout
      res.status(200).json({ success: true });
      console.log('✅ Webhook response sent immediately to Razorpay');

      // 🔄 Process webhook asynchronously after responding
      // This ensures Razorpay receives confirmation quickly
      setImmediate(async () => {
        try {
          // Handle only order.paid events for comprehensive transaction tracking
          switch (event.event) {
            case 'order.paid':
              console.log('💰 Order paid event received - processing payment completion');
              await handleOrderPaid(event.payload);
              break;
            case 'payment.captured':
              console.log('⚠️ Payment captured event received - ignoring (using order.paid instead)');
              break;
            case 'payment.failed':
              console.log('❌ Payment failed event received - payment not captured');
              break;
            default:
              console.log('⚠️ Unhandled webhook event:', event.event);
          }
        } catch (asyncError) {
          console.error('❌ Error in async webhook processing:', asyncError);
          // Error is logged but doesn't affect the response already sent to Razorpay
        }
      });

    } catch (error) {
      console.error('Webhook error:', error);
      // Only send error response if we haven't already responded
      try {
        res.status(500).json({ error: 'Internal server error' });
      } catch (responseError) {
        // Response already sent, ignore
        console.error('Response already sent, ignoring error response');
      }
    }
  }
);


/**
 * Send order-related FCM notification
 * Used by: Razorpay webhook + Payment/COD/Wallet flows
 */
async function sendOrderNotification(userId: string, orderId: string, type: string) {
  try {
    const notificationId = `${orderId}-${type}-${Date.now()}`;
    console.log(`[${notificationId}] 🔔 sendOrderNotification called - type: ${type}, userId: ${userId}, orderId: ${orderId}`);
    
    // Get user FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`[${notificationId}] ⚠️  User not found for FCM notification: ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`[${notificationId}] ⚠️  No FCM token found for user: ${userId}`);
      return;
    }

    // Get order details for notification content
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      console.log(`[${notificationId}] ⚠️  Order not found for notification: ${orderId}`);
      return;
    }

    const orderData = orderDoc.data();

    // Get total amount for notification
    const totalAmount =
      orderData?.paymentSummary?.totalOrderValue ??
      orderData?.pricingSummary?.totalBeforePayment ??
      orderData?.transactionDetails?.amount ??
      0;

    let title = '';
    let body = '';

    switch (type) {
      case 'payment_success':
        title = 'Payment Successful! 🎉';
        body = `Your payment of ₹${totalAmount} has been processed successfully. Order placed!`;
        break;
      case 'cod_order_placed':
        title = 'Order Placed Successfully! 📦';
        body = `Your COD order of ₹${totalAmount} has been confirmed. Pay when you receive your order!`;
        break;
      case 'wallet_order_placed':
        title = 'Order Placed Successfully! 💰';
        body = `Your wallet payment of ₹${totalAmount} has been processed. Order confirmed!`;
        break;
      case 'order_confirmed':
        title = 'Order Confirmed! 📦';
        body = 'Your order has been confirmed and is being prepared for shipment.';
        break;
      case 'order_shipped':
        title = 'Order Shipped! 🚚';
        body = 'Your order has been shipped and is on its way to you.';
        break;
      case 'order_cancelled':
        title = 'Order Cancelled 🔴';
        body = 'Your order has been cancelled. Refund will be processed shortly.';
        break;
      default:
        title = 'Order Update';
        body = 'Your order status has been updated.';
    }

    // Send FCM notification
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        type,
        orderId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high' as const,
        notification: {
          channelId: 'orders',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    console.log(`[${notificationId}] 🚀 Sending FCM message for order ${orderId}`);
    await messaging.send(message);
    console.log(`[${notificationId}] ✅ FCM notification sent for order: ${orderId}, type: ${type}`);

    // Store notification in Firestore for in-app history
    try {
      await db.collection('notifications').add({
        userId: userId,
        type: type,
        title: title,
        body: body,
        orderId: orderId,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
        readAt: null,
      });
      console.log(`[${notificationId}] ✅ Notification stored in Firestore for user: ${userId}`);
    } catch (storeError) {
      console.error(`[${notificationId}] ⚠️  Error storing notification in Firestore:`, storeError);
      // Don't fail the whole operation if storing fails
    }

  } catch (error) {
    console.error(`Error sending FCM notification:`, error);
  }
}

/**
 * Handle order.paid event with comprehensive transaction tracking
 * Expected payload structure:
 * {
 *   "order": {
 *     "entity": {
 *       "id": "order_xyz123",
 *       "amount": 23000,
 *       "currency": "INR",
 *       "status": "paid",
 *       "receipt": "receipt_ORD123"
 *     }
 *   },
 *   "payment": {
 *     "entity": {
 *       "id": "pay_abc456",
 *       "order_id": "order_xyz123",
 *       "amount": 23000,
 *       "currency": "INR",
 *       "status": "captured",
 *       "method": "upi",
 *       "captured": true,
 *       "created_at": 1642678800
 *     }
 *   }
 * }
 */
async function handleOrderPaid(payload: any) {
  try {
    const webhookId = `webhook-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    console.log(`[${webhookId}] 🔍 Processing order.paid event`);

    // Extract order and payment details from payload
    const orderEntity = payload.order?.entity;
    const paymentEntity = payload.payment?.entity;

    if (!orderEntity || !paymentEntity) {
      console.error(`[${webhookId}] ❌ Invalid order.paid payload structure`);
      return;
    }

    const razorpayOrderId = orderEntity.id;
    const paymentId = paymentEntity.id;
    const amount = paymentEntity.amount / 100; // Convert from paise to rupees
    const currency = paymentEntity.currency;
    const paymentMethod = paymentEntity.method;
    const capturedAt = new Date(paymentEntity.created_at * 1000); // Convert from Unix timestamp

    console.log(`[${webhookId}] 💰 Order paid details:`, {
      razorpayOrderId,
      paymentId,
      });

    // Find the razorpay order document using razorpayOrderId
    const razorpayOrderQuery = await db
      .collection('razorpay_orders')
      .where('razorpayOrderId', '==', razorpayOrderId)
      .limit(1)
      .get();

    if (razorpayOrderQuery.empty) {
      console.error('❌ No razorpay order found for order_id:', razorpayOrderId);
      return;
    }

    const razorpayOrderDoc = razorpayOrderQuery.docs[0];
    const razorpayOrderData = razorpayOrderDoc.data();
    const orderId = razorpayOrderData.orderId;
    const userId = razorpayOrderData.userId;
    const deliveryId = razorpayOrderData.deliveryId;

    console.log(`[${webhookId}] ✅ Found associated order: ${orderId}, userId: ${userId}`);

    // ✅ IDEMPOTENCY GUARD: Razorpay retries webhooks even after receiving 200.
    // If the order is already 'confirmed', this is a duplicate event — bail out
    const existingOrderSnap = await db.collection('orders').doc(orderId).get();
    if (existingOrderSnap.exists && existingOrderSnap.data()?.status === 'confirmed') {
      console.log(`[${webhookId}] ⏭️ Order ${orderId} already confirmed — skipping duplicate webhook event`);
      return;
    }

    // Update all documents in a transaction
    await db.runTransaction(async (transaction) => {
      const now = new Date();

      console.log(`[${webhookId}] 💾 Updating Firestore documents for order ${orderId}`);

      // 1. Update razorpay_orders document with comprehensive payment details
      transaction.update(razorpayOrderDoc.ref, {
        status: 'paid',
        paymentId: paymentId,
        paymentDetails: {
          amount: amount,
          currency: currency,
          method: paymentMethod,
          capturedAt: capturedAt,
          razorpayPaymentId: paymentId
        },
        updatedAt: now,
      });

      // 2. Update payments document with transaction details
      const paymentRef = db.collection('payments').doc(razorpayOrderData.paymentId);
      transaction.update(paymentRef, {
        status: 'captured',
        gatewayPaymentId: paymentId,
        transactionDetails: {
          razorpayPaymentId: paymentId,
          amount: amount,
          currency: currency,
          method: paymentMethod,
          capturedAt: capturedAt
        },
        capturedAt: capturedAt,
        updatedAt: now,
      });

      // 3. Update orders document
      const orderRef = db.collection('orders').doc(orderId);
      transaction.update(orderRef, {
        status: 'confirmed',
        paymentStatus: 'completed',
        transactionDetails: {
          razorpayPaymentId: paymentId,
          amount: amount,
          currency: currency,
          method: paymentMethod,
          capturedAt: capturedAt
        },
        updatedAt: now,
      });

      // 4. Update deliveries document
      const deliveryRef = db.collection('deliveries').doc(deliveryId);
      transaction.update(deliveryRef, {
        status: 'confirmed',
        confirmedAt: now,
        updatedAt: now,
      });

      console.log(`[${webhookId}] ✅ All Firestore documents updated for order: ${orderId}`);
    });

    // Send FCM notification
    console.log(`[${webhookId}] 📲 Sending payment_success FCM notification`);
    await sendOrderNotification(userId, orderId, 'payment_success');

    console.log(`[${webhookId}] ✅ Order paid event processed successfully for order: ${orderId}`);

  } catch (error) {
    console.error(`❌ Error handling order.paid event:`, error instanceof Error ? error.message : 'Unknown error');
  }
}

/**
 * Cancel order and process refund based on payment method
 * This function handles refunds for all 4 payment modes: razorpay, cod, wallet, partial_wallet
 * 
 * Required Payload Structure:
 * {
 *   orderId: string,
 *   cancelReason: string,
 *   refundAmount?: number (optional, defaults to original amount)
 * }
 */
export const cancelOrder = onCall(
  { cors: true },
  async (request) => {
    try {
      console.log('🔍 Firebase Function: cancelOrder called');
      console.log('🔍 Firebase Function: Request data:', JSON.stringify(request.data, null, 2));

      // Verify Firebase Auth token
      if (!request.auth) {
        throw new Error('Unauthorized');
      }

      const userId = request.auth.uid;
      const { orderId, cancelReason } = request.data;

      // Validate required fields
      if (!orderId) {
        throw new Error('Order ID is required');
      }
      if (!cancelReason) {
        throw new Error('Cancel reason is required');
      }

      console.log('🔍 Processing cancellation for order:', orderId, 'by user:', userId);

      // Get order details
      const orderRef = db.collection('orders').doc(orderId);
      const orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        throw new Error('Order not found');
      }

      const orderData = orderDoc.data()!;

      // Validate order ownership
      if (orderData.userId !== userId) {
        throw new Error('Unauthorized: Order does not belong to user');
      }

      // Check if order can be cancelled
      const currentStatus = orderData.status;
      if (['cancelled', 'delivered', 'completed'].includes(currentStatus)) {
        throw new Error(`Order cannot be cancelled. Current status: ${currentStatus}`);
      }

      const paymentMode = orderData.paymentMode;
      const paymentId = orderData.paymentId;
      const deliveryId = orderData.deliveryId;

      console.log('💰 Order details for cancellation:', {
        orderId,
        paymentMode,
        currentStatus,
        amountBreakdown: orderData.paymentSummary
      });

      // Calculate refund amount
      const originalAmount = orderData.paymentSummary?.totalOrderValue || 0;
      const finalRefundAmount = originalAmount;

      if (finalRefundAmount <= 0) {
        throw new Error('Invalid refund amount');
      }

      // Process refund based on payment mode
      let refundResult = null;

      switch (paymentMode) {
        case 'cod':
          refundResult = await handleCODRefund(orderId, paymentId, finalRefundAmount, cancelReason);
          break;
        case 'wallet':
          refundResult = await handleWalletRefund(orderId, paymentId, finalRefundAmount, userId, cancelReason);
          break;
        case 'razorpay':
          refundResult = await handleRazorpayRefund(orderId, paymentId, finalRefundAmount, cancelReason);
          break;
        case 'partial_wallet':
          refundResult = await handlePartialWalletRefund(orderId, paymentId, finalRefundAmount, userId, orderData.paymentSummary, cancelReason);
          break;
        default:
          throw new Error(`Unsupported payment mode for refund: ${paymentMode}`);
      }

      // Update order status in transaction
      await db.runTransaction(async (transaction) => {
        const now = new Date();

        // Update order document
        transaction.update(orderRef, {
          status: 'cancelled',
          paymentStatus: 'refunded',
          cancelledAt: now,
          cancelReason: cancelReason,
          refundDetails: refundResult,
          updatedAt: now,
        });

        // Update payment document
        if (paymentId) {
          const paymentRef = db.collection('payments').doc(paymentId);
          transaction.update(paymentRef, {
            status: 'refunded',
            refundDetails: refundResult,
            refundedAt: now,
            updatedAt: now,
          });
        }

        // Update delivery document
        if (deliveryId) {
          const deliveryRef = db.collection('deliveries').doc(deliveryId);
          transaction.update(deliveryRef, {
            status: 'cancelled',
            cancelledAt: now,
            cancelReason: cancelReason,
            updatedAt: now,
          });
        }

        console.log('✅ Updated all documents for cancelled order:', orderId);
      });

      // Send cancellation notification
      await sendOrderNotification(userId, orderId, 'order_cancelled');

      console.log('✅ Order cancellation completed successfully:', {
        orderId,
        paymentMode,
        refundAmount: finalRefundAmount,
        refundResult
      });

      return {
        success: true,
        orderId,
        refundAmount: finalRefundAmount,
        refundResult,
        message: 'Order cancelled and refund processed successfully'
      };

    } catch (error) {
      console.error('❌ Error cancelling order:', error);
      throw new Error(error instanceof Error ? error.message : 'Internal server error');
    }
  }
);

// =============================================================================
// REFUND HANDLERS FOR DIFFERENT PAYMENT MODES
// =============================================================================

/**
 * Handle COD refund - no actual refund needed, just update status
 */
async function handleCODRefund(orderId: string, paymentId: string, refundAmount: number, cancelReason: string): Promise<any> {
  console.log('💵 COD REFUND: No actual refund needed for COD orders');

  return {
    type: 'cod_cancellation',
    refundAmount: 0, // No refund for COD
    refundMethod: 'none',
    refundStatus: 'not_applicable',
    refundId: null,
    processedAt: new Date(),
    notes: 'COD order cancelled - no payment collected yet'
  };
}

/**
 * Handle wallet refund - credit amount back to user wallet
 */
async function handleWalletRefund(orderId: string, paymentId: string, refundAmount: number, userId: string, cancelReason: string): Promise<any> {
  console.log('💰 WALLET REFUND: Crediting amount back to user wallet');

  // Credit amount back to user wallet
  await db.runTransaction(async (transaction) => {
    const userRef = db.collection('users').doc(userId);
    transaction.update(userRef, {
      walletBalance: FieldValue.increment(refundAmount),
      updatedAt: new Date(),
    });
  });

  return {
    type: 'wallet_refund',
    refundAmount: refundAmount,
    refundMethod: 'wallet_credit',
    refundStatus: 'completed',
    refundId: `WALLET_REFUND_${Date.now()}`,
    processedAt: new Date(),
    notes: `₹${refundAmount} credited back to wallet`
  };
}

/**
 * Handle Razorpay refund - process refund via Razorpay API
 */
async function handleRazorpayRefund(orderId: string, paymentId: string, refundAmount: number, cancelReason: string): Promise<any> {
  console.log('💳 RAZORPAY REFUND: Processing refund via Razorpay API');

  // Get payment details from payments collection
  const paymentRef = db.collection('payments').doc(paymentId);
  const paymentDoc = await paymentRef.get();

  if (!paymentDoc.exists) {
    throw new Error('Payment record not found');
  }

  const paymentData = paymentDoc.data()!;
  const razorpayPaymentId = paymentData.gatewayPaymentId;

  if (!razorpayPaymentId) {
    throw new Error('Razorpay payment ID not found');
  }

  // Create refund via Razorpay API
  const refundData = {
    amount: Math.round(refundAmount * 100), // Convert to paise
    notes: {
      order_id: orderId,
      cancel_reason: cancelReason,
      refund_type: 'full_refund'
    }
  };

  console.log('🔍 Creating Razorpay refund:', refundData);

  const refundResponse = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}/refund`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${Buffer.from(`${getConfig().keyId}:${getConfig().keySecret}`).toString('base64')}`,
    },
    body: JSON.stringify(refundData),
  });

  if (!refundResponse.ok) {
    const error = await refundResponse.text();
    console.error('Razorpay refund API error:', error);
    throw new Error('Failed to process Razorpay refund');
  }

  const refundResult = await refundResponse.json();
  console.log('✅ Razorpay refund created:', refundResult.id);

  return {
    type: 'razorpay_refund',
    refundAmount: refundAmount,
    refundMethod: 'razorpay_api',
    refundStatus: refundResult.status,
    refundId: refundResult.id,
    razorpayRefundId: refundResult.id,
    processedAt: new Date(),
    notes: `Razorpay refund processed: ${refundResult.id}`
  };
}

/**
 * Handle partial wallet refund - refund both wallet and Razorpay portions
 */
async function handlePartialWalletRefund(
  orderId: string,
  paymentId: string,
  refundAmount: number,
  userId: string,
  paymentSummary: any,
  cancelReason: string
): Promise<any> {
  console.log('💰 PARTIAL WALLET REFUND: Processing refund for both wallet and Razorpay portions');

  const walletAmountUsed = paymentSummary?.walletPaidAmount || 0;
  const razorpayAmount = paymentSummary?.onlinePaidAmount || 0;

  console.log('💰 Partial wallet refund breakdown:', {
    totalRefund: refundAmount,
    walletPortion: walletAmountUsed,
    razorpayPortion: razorpayAmount
  });

  // Credit wallet portion back to user wallet
  if (walletAmountUsed > 0) {
    await db.runTransaction(async (transaction) => {
      const userRef = db.collection('users').doc(userId);
      transaction.update(userRef, {
        walletBalance: FieldValue.increment(walletAmountUsed),
        updatedAt: new Date(),
      });
    });
    console.log('✅ Wallet portion refunded:', walletAmountUsed);
  }

  // Process Razorpay refund for the remaining portion
  let razorpayRefundResult = null;
  if (razorpayAmount > 0) {
    // Get payment details
    const paymentRef = db.collection('payments').doc(paymentId);
    const paymentDoc = await paymentRef.get();

    if (paymentDoc.exists) {
      const paymentData = paymentDoc.data()!;
      const razorpayPaymentId = paymentData.gatewayPaymentId;

      if (razorpayPaymentId) {
        // Create Razorpay refund
        const refundData = {
          amount: Math.round(razorpayAmount * 100), // Convert to paise
          notes: {
            order_id: orderId,
            cancel_reason: cancelReason,
            refund_type: 'partial_wallet_refund'
          }
        };

        const refundResponse = await fetch(`https://api.razorpay.com/v1/payments/${razorpayPaymentId}/refund`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${Buffer.from(`${getConfig().keyId}:${getConfig().keySecret}`).toString('base64')}`,
          },
          body: JSON.stringify(refundData),
        });

        if (refundResponse.ok) {
          razorpayRefundResult = await refundResponse.json();
          console.log('✅ Razorpay portion refunded:', razorpayRefundResult.id);
        } else {
          console.error('❌ Razorpay refund failed');
        }
      }
    }
  }

  return {
    type: 'partial_wallet_refund',
    refundAmount: refundAmount,
    refundMethod: 'mixed',
    refundStatus: 'completed',
    refundId: `PARTIAL_WALLET_REFUND_${Date.now()}`,
    processedAt: new Date(),
    breakdown: {
      walletRefund: {
        amount: walletAmountUsed,
        method: 'wallet_credit',
        status: 'completed'
      },
      razorpayRefund: {
        amount: razorpayAmount,
        method: 'razorpay_api',
        status: razorpayRefundResult ? razorpayRefundResult.status : 'failed',
        refundId: razorpayRefundResult?.id || null
      }
    },
    notes: `Partial wallet refund: ₹${walletAmountUsed} to wallet, ₹${razorpayAmount} via Razorpay`
  };
}

// Note: completeRemainingPayment function removed as partial wallet now uses automatic Razorpay flow


