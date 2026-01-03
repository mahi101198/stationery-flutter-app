import * as nodemailer from 'nodemailer';
import * as logger from 'firebase-functions/logger';
/**
 * Configure the email transporter
 * Uses environment variables for credentials
 */
const transporter = nodemailer.createTransport({
    service: 'gmail', // You can change this to your preferred service
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});
/**
 * Send order confirmation email to admin
 */
export async function sendOrderConfirmationEmail(orderData, deliveryData) {
    var _a;
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
        const total = ((_a = orderData.pricing) === null || _a === void 0 ? void 0 : _a.total) || orderData.totalAmount || 0;
        // Format address
        const address = (deliveryData === null || deliveryData === void 0 ? void 0 : deliveryData.address) || {};
        const addressString = `
      ${address.recipientName || 'N/A'}
      ${address.line1 || ''}
      ${address.line2 || ''}
      ${address.city || ''}, ${address.state || ''} - ${address.pincode || ''}
      Phone: ${address.mobileNumber || ''}
    `;
        // Format items list
        const itemsList = items.map((item) => `- ${item.name} x ${item.quantity} (₹${item.price})`).join('\n');
        const mailOptions = {
            from: `"RPS Stationery" <${process.env.EMAIL_USER}>`,
            to: adminEmail,
            subject: `New Order Confirmed: #${orderId}`,
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
        <h2>New Order Confirmed!</h2>
        <p><strong>Order ID:</strong> ${orderId}</p>
        <p><strong>Total Amount:</strong> ₹${total}</p>
        
        <h3>Items:</h3>
        <ul>
          ${items.map((item) => `<li>${item.name} x ${item.quantity} (₹${item.price})</li>`).join('')}
        </ul>
        
        <h3>Delivery Address:</h3>
        <p style="white-space: pre-line;">${addressString}</p>
        
        <p><strong>Payment Status:</strong> ${orderData.paymentStatus || 'N/A'}</p>
        <p><strong>Payment Mode:</strong> ${orderData.paymentMode || 'N/A'}</p>
      `,
        };
        const info = await transporter.sendMail(mailOptions);
        logger.info(`📧 Order confirmation email sent: ${info.messageId}`);
        return info;
    }
    catch (error) {
        logger.error('❌ Error sending order confirmation email:', error);
        throw error;
    }
}
//# sourceMappingURL=email-service.js.map