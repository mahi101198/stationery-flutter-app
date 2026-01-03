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
 *   items: Array<{productId, name, price, quantity, productImage?, category?, brand?}>,
 *   amountSummary: {subTotal, discount, walletUsed, deliveryFee, finalPayable},
 *   paymentMode: 'razorpay'|'cod'|'wallet'|'partial_wallet',
 *   couponCode?: string,
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
      console.log('🔍 Firebase Function: Request data:', JSON.stringify(request.data, null, 2));

      // Verify Firebase Auth token
      if (!request.auth) {
        throw new Error('Unauthorized');
      }

      const userId = request.auth.uid;

      // Extract data from comprehensive payload
      const {
        items,
        amountSummary,           // Comprehensive price breakdown
        paymentMode,
        couponCode,              // Coupon code
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
      if (!amountSummary) {
        throw new Error('amountSummary is required');
      }

      // Extract and validate comprehensive amount breakdown
      const subTotal = amountSummary.subTotal || 0;
      const discountAmount = amountSummary.discount || 0;
      const walletAmountUsed = amountSummary.walletUsed || 0;
      const deliveryFee = amountSummary.deliveryFee || 0;
      const finalAmount = amountSummary.finalPayable || 0;
      const totalOrderAmount = amountSummary.totalOrderAmount || 0;

      // Validate comprehensive amounts
      if (subTotal <= 0) {
        throw new Error('Subtotal must be greater than 0');
      }
      if (finalAmount < 0) {
        throw new Error('Final payable amount cannot be negative');
      }
      if (walletAmountUsed < 0) {
        throw new Error('Wallet amount used cannot be negative');
      }
      if (discountAmount < 0) {
        throw new Error('Discount amount cannot be negative');
      }
      if (deliveryFee < 0) {
        throw new Error('Delivery fee cannot be negative');
      }
      if (totalOrderAmount <= 0) {
        throw new Error('Total order amount must be greater than 0');
      }

      // Double-check validation for partial wallet payments
      if (paymentMode === 'partial_wallet') {
        // Validate wallet amount
        if (walletAmountUsed <= 0) {
          throw new Error('Valid wallet amount is required for partial wallet payment');
        }

        // Validate final payable amount consistency
        // Formula: finalPayable = subTotal + deliveryFee - discount - walletUsed
        const expectedFinalAmount = subTotal + deliveryFee - discountAmount - walletAmountUsed;
        if (Math.abs(finalAmount - expectedFinalAmount) > 0.01) {
          throw new Error(`Final payable amount (${finalAmount}) does not match expected amount (${expectedFinalAmount}). Breakdown: subTotal(${subTotal}) + delivery(${deliveryFee}) - discount(${discountAmount}) - wallet(${walletAmountUsed})`);
        }

        // Validate that wallet amount doesn't exceed the order total after discount
        const totalAfterDiscount = subTotal + deliveryFee - discountAmount;
        if (walletAmountUsed >= totalAfterDiscount) {
          throw new Error(`Wallet amount (${walletAmountUsed}) must be less than total after discount (${totalAfterDiscount}) for partial payment`);
        }

        console.log('✅ Partial wallet validation passed:', {
          subTotal,
          deliveryFee,
          discount: discountAmount,
          walletUsed: walletAmountUsed,
          finalPayable: finalAmount,
          expectedFinalAmount
        });
      }

      console.log('🔍 Firebase Function: Creating order for user:', userId);
      console.log('🔍 Firebase Function: Payment mode:', paymentMode);
      console.log('💰 Amount Summary:', {
        subTotal,
        discount: discountAmount,
        walletUsed: walletAmountUsed,
        deliveryFee,
        finalPayable: finalAmount,
        totalOrderAmount
      });

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
          razorpayOrderId = await handlePartialWalletPayment(orderId, userId, paymentId, totalOrderAmount, currency, walletAmountUsed);
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

          // Calculate amount for razorpay_orders (full amount for razorpay, remaining amount for partial_wallet)
          const razorpayAmount = paymentMode === 'partial_wallet'
            ? Math.round(finalAmount * 100) // finalAmount is already the remaining amount after wallet deduction
            : Math.round(finalAmount * 100);

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
            walletAmount: paymentMode === 'partial_wallet' ? walletAmountUsed : null,
            totalAmount: paymentMode === 'partial_wallet' ? totalOrderAmount : null,
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

          // Comprehensive amount breakdown
          amountBreakdown: {
            subTotal,
            discount: discountAmount,
            deliveryFee,
            walletUsed: walletAmountUsed,
            finalAmount: finalAmount,
            totalOrderAmount
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
            discountApplied: discountAmount,
            appliedAt: now
          } : null,

          // Wallet information
          walletInfo: (isWalletFull || isWalletPartial) ? {
            amountUsed: walletAmountUsed,
            isPartialPayment: isWalletPartial,
            remainingAmount: isWalletPartial ? finalAmount : 0, // finalAmount is already the remaining amount
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

          // Comprehensive item details
          items: items.map((item: any) => ({
            productId: item.productId,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
            subtotal: item.price * item.quantity,
            productImage: item.productImage || null,
            discountPrice: item.discountPrice || item.price,
            totalPrice: (item.discountPrice || item.price) * item.quantity,
            // Additional item metadata
            itemMetadata: {
              originalPrice: item.price,
              appliedDiscount: item.discountPrice ? (item.price - item.discountPrice) : 0,
              category: item.category || null,
              brand: item.brand || null
            }
          })),

          // Comprehensive amount breakdown
          amountBreakdown: {
            subTotal,
            discount: discountAmount,
            deliveryFee,
            walletUsed: walletAmountUsed,
            finalAmount: finalAmount,
            totalOrderAmount: totalOrderAmount, // Add total order amount for notifications
            // Additional breakdown
            taxAmount: 0, // Can be added if needed
            serviceCharge: 0, // Can be added if needed
            totalSavings: discountAmount + walletAmountUsed
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

        // Comprehensive amount breakdown
        amountBreakdown: {
          subTotal,
          discount: discountAmount,
          deliveryFee,
          walletUsed: walletAmountUsed,
          finalAmount: finalAmount,
          totalOrderAmount,
          totalSavings: discountAmount + walletAmountUsed
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
          discountApplied: discountAmount
        } : null,

        // Wallet information
        walletInfo: (isWalletFull || isWalletPartial) ? {
          amountUsed: walletAmountUsed,
          isPartialPayment: isWalletPartial,
          remainingAmount: isWalletPartial ? finalAmount : 0, // finalAmount is already the remaining amount
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
 */
async function sendOrderNotification(userId: string, orderId: string, type: string) {
  try {
    // Get user FCM token
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log('User not found for FCM notification:', userId);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token found for user:', userId);
      return;
    }

    // Get order details for notification content
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      console.log('Order not found for notification:', orderId);
      return;
    }

    const orderData = orderDoc.data();
    const totalAmount = orderData?.amountBreakdown?.totalOrderAmount || orderData?.amountBreakdown?.finalAmount || 0;

    console.log('📧 Notification amount debug:');
    console.log('  - amountBreakdown:', orderData?.amountBreakdown);
    console.log('  - totalOrderAmount:', orderData?.amountBreakdown?.totalOrderAmount);
    console.log('  - finalAmount:', orderData?.amountBreakdown?.finalAmount);
    console.log('  - Using amount:', totalAmount);

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

    await messaging.send(message);
    console.log('✅ FCM notification sent for order:', orderId, 'type:', type);

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
      console.log('✅ Notification stored in Firestore for user:', userId);
    } catch (storeError) {
      console.error('Error storing notification in Firestore:', storeError);
      // Don't fail the whole operation if storing fails
    }

  } catch (error) {
    console.error('Error sending FCM notification:', error);
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
    console.log('🔍 Processing order.paid event with payload:', JSON.stringify(payload, null, 2));

    // Extract order and payment details from payload
    const orderEntity = payload.order?.entity;
    const paymentEntity = payload.payment?.entity;

    if (!orderEntity || !paymentEntity) {
      console.error('❌ Invalid order.paid payload structure');
      return;
    }

    const razorpayOrderId = orderEntity.id;
    const paymentId = paymentEntity.id;
    const amount = paymentEntity.amount / 100; // Convert from paise to rupees
    const currency = paymentEntity.currency;
    const paymentMethod = paymentEntity.method;
    const capturedAt = new Date(paymentEntity.created_at * 1000); // Convert from Unix timestamp

    console.log('💰 Order paid details:', {
      razorpayOrderId,
      paymentId,
      amount,
      currency,
      paymentMethod,
      capturedAt
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

    console.log('✅ Found associated order:', {
      orderId,
      userId,
      deliveryId,
      isPartialWallet: razorpayOrderData.isPartialWalletPayment
    });

    // Update all documents in a transaction
    await db.runTransaction(async (transaction) => {
      const now = new Date();

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

      console.log('✅ Updated all documents for order:', orderId);
    });

    // Send FCM notification
    await sendOrderNotification(userId, orderId, 'payment_success');

    console.log('✅ Order paid event processed successfully:', {
      orderId,
      paymentId,
      amount,
      isPartialWallet: razorpayOrderData.isPartialWalletPayment
    });

  } catch (error) {
    console.error('❌ Error handling order.paid event:', error instanceof Error ? error.message : 'Unknown error');
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
      const { orderId, cancelReason, refundAmount } = request.data;

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
        amountBreakdown: orderData.amountBreakdown
      });

      // Calculate refund amount
      const originalAmount = orderData.amountBreakdown?.totalOrderAmount || orderData.amountBreakdown?.finalAmount || 0;
      const finalRefundAmount = refundAmount || originalAmount;

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
          refundResult = await handlePartialWalletRefund(orderId, paymentId, finalRefundAmount, userId, orderData.amountBreakdown, cancelReason);
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
  amountBreakdown: any,
  cancelReason: string
): Promise<any> {
  console.log('💰 PARTIAL WALLET REFUND: Processing refund for both wallet and Razorpay portions');

  const walletAmountUsed = amountBreakdown?.walletUsed || 0;
  const razorpayAmount = amountBreakdown?.finalAmount || 0;

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


