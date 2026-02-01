import * as nodemailer from 'nodemailer';
import * as logger from 'firebase-functions/logger';

/**
 * Helper function to validate email addresses
 */
function isValidEmail(email: string): boolean {
    if (!email) return false;
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Configure the email transporter
 * Uses Zoho Mail SMTP for sending emails
 * Host: smtp.zoho.in
 * Port: 465 (SSL)
 */
const transporter = nodemailer.createTransport({
    host: 'smtp.zoho.in',
    port: 465,
    secure: true, // true for 465, false for other ports
    auth: {
        user: 'rps@rajasthanpustaksadan.com',
        pass: "1vk2WUQUcvLP",
    },
});

/**
 * Send order confirmation email to both admin and customer
 */
export async function sendOrderConfirmationEmail(orderData: any, deliveryData: any) {
    try {
        const adminEmail = process.env.ADMIN_EMAIL;

        if (!adminEmail) {
            logger.warn('ADMIN_EMAIL environment variable not set. Skipping email.');
            return;
        }

        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
            logger.warn('Email credentials not set. Skipping email.');
            return;
        }

        const orderId = orderData.orderId || orderData.id;
        const items = orderData.items || [];
        const total = orderData.pricing?.total || orderData.totalOrderValue || 0;

        // Format address
        const address = deliveryData?.address || {};

        // Extract customer email from address or order data
        const customerEmail = address.email || address.mobileNumber || orderData.customerEmail || null;
        const addressString = `
      ${address.recipientName || 'N/A'}
      ${address.line1 || ''}
      ${address.line2 || ''}
      ${address.city || ''}, ${address.state || ''} - ${address.pincode || ''}
      Phone: ${address.mobileNumber || ''}
    `;

        // Format items list
        const itemsList = items.map((item: any) =>
            `- ${item.name} x ${item.quantity} (₹${item.price})`
        ).join('\n');

        // Generate items table HTML
        const itemsTableHTML = items.map((item: any) => `
          <tr style="border-bottom: 1px solid #e0e0e0;">
            <td style="padding: 12px 0; text-align: left; color: #333;">${item.name}</td>
            <td style="padding: 12px 0; text-align: center; color: #333;">${item.quantity}</td>
            <td style="padding: 12px 0; text-align: right; color: #333;">₹${item.price}</td>
            <td style="padding: 12px 0; text-align: right; color: #333;">₹${(item.price * item.quantity).toFixed(2)}</td>
          </tr>
        `).join('');

        const mailOptions = {
            from: `"RPS Rajasthan Pustak Sadan" <${process.env.EMAIL_USER}>`,
            to: adminEmail,
            subject: `📦 New Order Confirmed: #${orderId}`,
            text: `
New Order Confirmed!

Order ID: ${orderId}
Total Amount: ₹${total}

Items:
${itemsList}

Delivery Address:
${addressString}

Payment Status: ${orderData.paymentStatus || 'N/A'}
Payment Mode: ${orderData.paymentMode || 'N/A'}
      `,
            html: `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .header p {
            margin: 8px 0 0 0;
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 30px 20px;
        }
        .order-summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-left: 4px solid #667eea;
            margin-bottom: 25px;
            border-radius: 4px;
        }
        .order-summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .order-summary-row:last-child {
            margin-bottom: 0;
        }
        .summary-label {
            color: #666;
            font-size: 14px;
            font-weight: 500;
        }
        .summary-value {
            color: #333;
            font-size: 14px;
            font-weight: 600;
        }
        .section-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-top: 25px;
            margin-bottom: 15px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .items-table th {
            background-color: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e0e0e0;
            font-size: 13px;
        }
        .items-table th:nth-child(2),
        .items-table th:nth-child(3),
        .items-table th:nth-child(4) {
            text-align: center;
        }
        .items-table th:nth-child(3),
        .items-table th:nth-child(4) {
            text-align: right;
        }
        .items-table td {
            padding: 12px 0;
            border-bottom: 1px solid #e0e0e0;
            color: #333;
            font-size: 14px;
        }
        .items-table td:nth-child(2),
        .items-table td:nth-child(3),
        .items-table td:nth-child(4) {
            text-align: center;
        }
        .items-table td:nth-child(3),
        .items-table td:nth-child(4) {
            text-align: right;
        }
        .total-row {
            background-color: #f8f9fa;
            font-weight: 600;
            font-size: 15px;
            color: #667eea;
        }
        .address-box {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            margin-top: 10px;
            line-height: 1.6;
            color: #333;
            font-size: 14px;
            white-space: pre-line;
        }
        .payment-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 20px;
        }
        .payment-info-item {
            background-color: #f8f9fa;
            padding: 12px;
            border-radius: 4px;
        }
        .payment-info-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
        }
        .payment-info-value {
            font-size: 14px;
            font-weight: 600;
            color: #333;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
            font-size: 12px;
            color: #666;
        }
        .footer p {
            margin: 5px 0;
        }
        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            margin-top: 10px;
        }
        .status-confirmed {
            background-color: #d4edda;
            color: #155724;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📦 Order Confirmed</h1>
            <p>Thank you for your order!</p>
        </div>
        
        <div class="content">
            <div class="order-summary">
                <div class="order-summary-row">
                    <span class="summary-label">Order ID:</span>
                    <span class="summary-value">#${orderId}</span>
                </div>
                <div class="order-summary-row">
                    <span class="summary-label">Order Date:</span>
                    <span class="summary-value">${new Date().toLocaleDateString('en-IN', { year: 'numeric', month: 'long', day: 'numeric' })}</span>
                </div>
                <div class="order-summary-row">
                    <span class="summary-label">Order Total:</span>
                    <span class="summary-value" style="color: #667eea; font-size: 16px;">₹${total.toFixed(2)}</span>
                </div>
            </div>

            <div class="section-title">📋 Order Items</div>
            <table class="items-table">
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Qty</th>
                        <th>Unit Price</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${itemsTableHTML}
                    <tr class="total-row">
                        <td colspan="3" style="text-align: right; padding: 15px 0;">Grand Total:</td>
                        <td style="text-align: right; padding: 15px 0;">₹${total.toFixed(2)}</td>
                    </tr>
                </tbody>
            </table>

            <div class="section-title">🏠 Delivery Address</div>
            <div class="address-box">${addressString.trim()}</div>

            <div class="section-title">💳 Payment Details</div>
            <div class="payment-info">
                <div class="payment-info-item">
                    <div class="payment-info-label">Payment Status</div>
                    <div class="payment-info-value">${orderData.paymentStatus ? orderData.paymentStatus.charAt(0).toUpperCase() + orderData.paymentStatus.slice(1) : 'Pending'}</div>
                </div>
                <div class="payment-info-item">
                    <div class="payment-info-label">Payment Mode</div>
                    <div class="payment-info-value">${orderData.paymentMode ? orderData.paymentMode.toUpperCase() : 'N/A'}</div>
                </div>
            </div>

            <div style="text-align: center;">
                <span class="status-badge status-confirmed">✓ Order Confirmed</span>
            </div>
        </div>

        <div class="footer">
            <p><strong>RPS Rajasthan Pustak Sadan</strong></p>
            <p>📍 Rajasthan, India</p>
            <p>Thank you for shopping with us!</p>
            <p style="margin-top: 15px; border-top: 1px solid #ddd; padding-top: 15px;">
                This is an automated email. Please do not reply to this address.
            </p>
        </div>
    </div>
</body>
</html>
            `,
        };

        // Send to Admin
        try {
            const adminInfo = await transporter.sendMail(mailOptions);
            logger.info(`📧 Order confirmation email sent to ADMIN: ${adminInfo.messageId}`);
        } catch (adminError) {
            logger.error('❌ Error sending order confirmation email to admin:', adminError);
        }

        // Send to Customer if email exists
        if (customerEmail && isValidEmail(customerEmail)) {
            const customerMailOptions = {
                ...mailOptions,
                to: customerEmail,
                subject: `✅ Your Order Confirmed: #${orderId}`,
                text: `
Your Order Confirmation!

Order ID: ${orderId}
Total Amount: ₹${total}

Items:
${itemsList}

Delivery Address:
${addressString}

Payment Status: ${orderData.paymentStatus || 'N/A'}
Payment Mode: ${orderData.paymentMode || 'N/A'}

Thank you for your purchase! Your order has been confirmed and will be processed shortly.
                `,
                html: `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #27ae60 0%, #229954 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .header p {
            margin: 8px 0 0 0;
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 30px 20px;
        }
        .greeting {
            font-size: 16px;
            color: #333;
            margin-bottom: 20px;
            line-height: 1.6;
        }
        .order-summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-left: 4px solid #27ae60;
            margin-bottom: 25px;
            border-radius: 4px;
        }
        .order-summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .order-summary-row:last-child {
            margin-bottom: 0;
        }
        .summary-label {
            color: #666;
            font-size: 14px;
            font-weight: 500;
        }
        .summary-value {
            color: #333;
            font-size: 14px;
            font-weight: 600;
        }
        .section-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-top: 25px;
            margin-bottom: 15px;
            border-bottom: 2px solid #27ae60;
            padding-bottom: 10px;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .items-table th {
            background-color: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e0e0e0;
            font-size: 13px;
        }
        .items-table th:nth-child(2),
        .items-table th:nth-child(3),
        .items-table th:nth-child(4) {
            text-align: right;
        }
        .items-table td {
            padding: 12px 0;
            border-bottom: 1px solid #e0e0e0;
            color: #333;
            font-size: 14px;
        }
        .items-table td:nth-child(2),
        .items-table td:nth-child(3),
        .items-table td:nth-child(4) {
            text-align: right;
        }
        .total-row {
            background-color: #f8f9fa;
            font-weight: 600;
            font-size: 15px;
            color: #27ae60;
        }
        .address-box {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
            margin-top: 10px;
            line-height: 1.6;
            color: #333;
            font-size: 14px;
            white-space: pre-line;
        }
        .status-badge {
            display: inline-block;
            background-color: #27ae60;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 600;
            margin-top: 15px;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
            font-size: 12px;
            color: #666;
        }
        .footer p {
            margin: 5px 0;
        }
        .next-steps {
            background-color: #e8f5e9;
            border-left: 4px solid #27ae60;
            padding: 15px;
            margin-top: 20px;
            border-radius: 4px;
        }
        .next-steps p {
            margin: 8px 0;
            color: #333;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>✅ Order Confirmed!</h1>
            <p>Order #${orderId}</p>
        </div>
        
        <div class="content">
            <div class="greeting">
                <p>Dear ${address.recipientName || 'Valued Customer'},</p>
                <p>Thank you for your order! We're excited to process your purchase. Your order has been successfully confirmed and is being prepared for shipment.</p>
            </div>

            <div class="order-summary">
                <div class="order-summary-row">
                    <span class="summary-label">Order ID:</span>
                    <span class="summary-value">#${orderId}</span>
                </div>
                <div class="order-summary-row">
                    <span class="summary-label">Order Total:</span>
                    <span class="summary-value">₹${total.toFixed(2)}</span>
                </div>
                <div class="order-summary-row">
                    <span class="summary-label">Payment Status:</span>
                    <span class="summary-value">${orderData.paymentStatus ? orderData.paymentStatus.charAt(0).toUpperCase() + orderData.paymentStatus.slice(1) : 'Pending'}</span>
                </div>
            </div>

            ${items.length > 0 ? `
            <div class="section-title">📦 Order Items</div>
            <table class="items-table">
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Qty</th>
                        <th>Price</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${itemsTableHTML}
                    <tr class="total-row">
                        <td colspan="3" style="text-align: right; padding: 15px 0;">Grand Total:</td>
                        <td style="text-align: right; padding: 15px 0;">₹${total.toFixed(2)}</td>
                    </tr>
                </tbody>
            </table>
            ` : ''}

            <div class="section-title">📍 Delivery Address</div>
            <div class="address-box">${addressString}</div>

            <div class="next-steps">
                <p><strong>What's Next?</strong></p>
                <p>✓ Your order is being packed with care</p>
                <p>✓ You'll receive a shipping notification soon</p>
                <p>✓ Track your order status anytime</p>
            </div>

            <div style="text-align: center;">
                <span class="status-badge">✅ Order Confirmed</span>
            </div>
        </div>

        <div class="footer">
            <p><strong>RPS Rajasthan Pustak Sadan</strong></p>
            <p>📍 Rajasthan, India</p>
            <p>Thank you for shopping with us!</p>
            <p style="margin-top: 15px; border-top: 1px solid #ddd; padding-top: 15px; color: #999;">
                For any queries, please contact our support team.
            </p>
        </div>
    </div>
</body>
</html>
                `,
            };

            try {
                const customerInfo = await transporter.sendMail(customerMailOptions);
                logger.info(`📧 Order confirmation email sent to CUSTOMER (${customerEmail}): ${customerInfo.messageId}`);
            } catch (customerError) {
                logger.error(`⚠️ Error sending order confirmation email to customer (${customerEmail}):`, customerError);
            }
        } else {
            logger.warn(`No valid customer email found for order ${orderId}. Skipping customer notification.`);
        }

        return true;

    } catch (error) {
        logger.error('❌ Error in order confirmation email process:', error);
        throw error;
    }
}
/**
 * Send order status update email to admin
 * Sends when order status changes to various states
 */
export async function sendOrderStatusUpdateEmail(orderId: string, orderData: any, previousStatus: string, newStatus: string) {
    try {
        const adminEmail = process.env.ADMIN_EMAIL;

        if (!adminEmail) {
            logger.warn('ADMIN_EMAIL environment variable not set. Skipping email.');
            return;
        }

        if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
            logger.warn('Email credentials not set. Skipping email.');
            return;
        }

        // Status emojis and descriptions
        const statusConfig: { [key: string]: { emoji: string; title: string; color: string; description: string } } = {
            'placed': { emoji: '📝', title: 'Order Placed', color: '#3498db', description: 'Customer has successfully placed the order' },
            'confirmed': { emoji: '✅', title: 'Order Confirmed', color: '#667eea', description: 'Order has been confirmed by staff' },
            'packed': { emoji: '📦', title: 'Order Packed', color: '#f39c12', description: 'Order has been packed and ready for shipment' },
            'shipped': { emoji: '🚚', title: 'Order Shipped', color: '#9b59b6', description: 'Order is on its way to the delivery address' },
            'outForDelivery': { emoji: '📍', title: 'Out for Delivery', color: '#e74c3c', description: 'Order is out for delivery today' },
            'delivered': { emoji: '🎉', title: 'Order Delivered', color: '#27ae60', description: 'Order has been successfully delivered' },
            'cancelled': { emoji: '❌', title: 'Order Cancelled', color: '#c0392b', description: 'Order has been cancelled' },
            'returned': { emoji: '↩️', title: 'Order Returned', color: '#95a5a6', description: 'Order has been returned' },
            'refunded': { emoji: '💰', title: 'Order Refunded', color: '#16a085', description: 'Refund has been processed' },
        };

        const config = statusConfig[newStatus] || { emoji: '📋', title: newStatus, color: '#34495e', description: 'Order status updated' };

        const items = orderData.items || [];
        const total = orderData.pricing?.total || orderData.totalAmount || 0;

        const itemsTableHTML = items.map((item: any) => `
          <tr style="border-bottom: 1px solid #e0e0e0;">
            <td style="padding: 10px 0; text-align: left; color: #333;">${item.name}</td>
            <td style="padding: 10px 0; text-align: center; color: #333;">${item.quantity}</td>
            <td style="padding: 10px 0; text-align: right; color: #333;">₹${(item.price * item.quantity).toFixed(2)}</td>
          </tr>
        `).join('');

        const mailOptions = {
            from: `"RPS Rajasthan Pustak Sadan" <${process.env.EMAIL_USER}>`,
            to: adminEmail,
            subject: `${config.emoji} Order Status Update: #${orderId} - ${config.title}`,
            text: `
Order Status Updated!

Order ID: ${orderId}
Previous Status: ${previousStatus}
New Status: ${newStatus}
Total Amount: ₹${total}

Items:
${items.map((item: any) => `- ${item.name} x ${item.quantity} (₹${(item.price * item.quantity).toFixed(2)})`).join('\n')}

Update: ${config.description}
            `,
            html: `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, ${config.color} 0%, rgba(102, 126, 234, 0.8) 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .header p {
            margin: 8px 0 0 0;
            font-size: 14px;
            opacity: 0.9;
        }
        .content {
            padding: 30px 20px;
        }
        .status-box {
            background: linear-gradient(135deg, ${config.color}15 0%, ${config.color}05 100%);
            border-left: 4px solid ${config.color};
            padding: 20px;
            margin-bottom: 25px;
            border-radius: 4px;
        }
        .status-emoji {
            font-size: 40px;
            margin-bottom: 10px;
        }
        .status-title {
            font-size: 20px;
            font-weight: 600;
            color: ${config.color};
            margin: 0;
        }
        .status-description {
            color: #666;
            font-size: 14px;
            margin: 8px 0 0 0;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 25px;
        }
        .info-item {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 4px;
        }
        .info-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
        }
        .info-value {
            font-size: 14px;
            font-weight: 600;
            color: #333;
        }
        .section-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-top: 25px;
            margin-bottom: 15px;
            border-bottom: 2px solid ${config.color};
            padding-bottom: 10px;
        }
        .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .items-table th {
            background-color: #f8f9fa;
            padding: 12px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e0e0e0;
            font-size: 13px;
        }
        .items-table th:nth-child(2),
        .items-table th:nth-child(3) {
            text-align: right;
        }
        .items-table td {
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
            color: #333;
            font-size: 14px;
        }
        .items-table td:nth-child(2),
        .items-table td:nth-child(3) {
            text-align: right;
        }
        .total-row {
            background-color: #f8f9fa;
            font-weight: 600;
            font-size: 15px;
            color: ${config.color};
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
            font-size: 12px;
            color: #666;
        }
        .footer p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${config.emoji} Order Status Update</h1>
            <p>Order #${orderId}</p>
        </div>
        
        <div class="content">
            <div class="status-box">
                <div class="status-emoji">${config.emoji}</div>
                <h2 class="status-title">${config.title}</h2>
                <p class="status-description">${config.description}</p>
            </div>

            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Order ID</div>
                    <div class="info-value">#${orderId}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Order Total</div>
                    <div class="info-value">₹${total.toFixed(2)}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Previous Status</div>
                    <div class="info-value" style="text-transform: capitalize;">${previousStatus}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Current Status</div>
                    <div class="info-value" style="text-transform: capitalize; color: ${config.color};">${newStatus}</div>
                </div>
            </div>

            ${items.length > 0 ? `
            <div class="section-title">📦 Order Items</div>
            <table class="items-table">
                <thead>
                    <tr>
                        <th>Product</th>
                        <th>Qty</th>
                        <th>Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${itemsTableHTML}
                    <tr class="total-row">
                        <td colspan="2" style="text-align: right; padding: 15px 0;">Grand Total:</td>
                        <td style="text-align: right; padding: 15px 0;">₹${total.toFixed(2)}</td>
                    </tr>
                </tbody>
            </table>
            ` : ''}

            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 4px; margin-top: 20px;">
                <p style="margin: 0; color: #666; font-size: 13px;">
                    <strong>Update Time:</strong> ${new Date().toLocaleString('en-IN')}
                </p>
            </div>
        </div>

        <div class="footer">
            <p><strong>RPS Rajasthan Pustak Sadan</strong></p>
            <p>📍 Rajasthan, India</p>
            <p>Your trusted stationery partner</p>
            <p style="margin-top: 15px; border-top: 1px solid #ddd; padding-top: 15px;">
                This is an automated email. Please do not reply to this address.
            </p>
        </div>
    </div>
</body>
</html>
            `,
        };

        const info = await transporter.sendMail(mailOptions);
        logger.info(`📧 Order status update email sent: ${info.messageId}`);
        return info;

    } catch (error) {
        logger.error('❌ Error sending order status update email:', error);
        throw error;
    }
}