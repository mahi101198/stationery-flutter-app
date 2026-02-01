# Email Setup Documentation - RPS Stationery

## Overview
This document details the email notification system for order status updates in the RPS Stationery application.

---

## 📧 Email Configuration

### SMTP Server Details
- **Host:** `smtp.zoho.in`
- **Port:** `465`
- **Protocol:** SSL
- **Email:** `rps@rajasthanpustaksadan.com`

### Environment Variables Required
Add these to your Firebase Cloud Functions `.env.local` file:

```
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=<Your Zoho Mail Password>
ADMIN_EMAIL=<Admin Email Address>
```

### Firebase Cloud Functions Configuration
Location: `functions/.env.local`

```env
# Zoho Mail SMTP Configuration
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=your_zoho_password_here

# Admin notification email
ADMIN_EMAIL=admin@rajasthanpustaksadan.com
```

---

## 📬 Email Functions

### 1. Order Confirmation Email
**Function:** `sendOrderConfirmationEmail(orderData, deliveryData)`

**Triggered When:**
- Order status changes to "confirmed" (from "placed")

**Contains:**
- Order ID and date
- Itemized list with prices and quantities
- Delivery address details
- Payment status and method
- Total amount with tax breakdown

**Template Style:** Professional HTML with gradient header, color-coded sections

---

### 2. Order Status Update Email
**Function:** `sendOrderStatusUpdateEmail(orderId, orderData, previousStatus, newStatus)`

**Triggered When:**
- Order status changes to any of these states:
  - `placed` - Order placed by customer
  - `confirmed` - Order confirmed by admin
  - `packed` - Order packed and ready for shipment
  - `shipped` - Order dispatched
  - `outForDelivery` - Out for delivery
  - `delivered` - Successfully delivered
  - `cancelled` - Order cancelled
  - `returned` - Order returned
  - `refunded` - Refund processed

**Features:**
- Dynamic color coding based on status
- Status-specific emoji and description
- Status transition information
- Order summary with items
- Timestamp of status change
- Visual indicators with gradient headers

**Status Mapping:**
| Status | Emoji | Color | Description |
|--------|-------|-------|-------------|
| placed | 📝 | #3498db (Blue) | Customer has placed the order |
| confirmed | ✅ | #667eea (Purple) | Order confirmed by staff |
| packed | 📦 | #f39c12 (Orange) | Order packed for shipment |
| shipped | 🚚 | #9b59b6 (Purple) | Order on the way |
| outForDelivery | 📍 | #e74c3c (Red) | Out for delivery today |
| delivered | 🎉 | #27ae60 (Green) | Successfully delivered |
| cancelled | ❌ | #c0392b (Dark Red) | Order cancelled |
| returned | ↩️ | #95a5a6 (Gray) | Order returned |
| refunded | 💰 | #16a085 (Teal) | Refund processed |

---

## 🎨 Email Template Design

### HTML Email Template Features

1. **Responsive Design**
   - Works on desktop and mobile devices
   - Max-width: 600px for optimal readability
   - Proper spacing and padding

2. **Color Scheme**
   - Primary colors: Purple (#667eea) and gradients
   - Status-specific colors for visual hierarchy
   - Professional, accessible color palette

3. **Visual Elements**
   - Gradient headers with emoji indicators
   - Color-coded status badges
   - Organized info grid layout
   - Item table with pricing breakdown
   - Footer with company branding

4. **Typography**
   - Font: Segoe UI, Tahoma, Geneva, Verdana (fallback)
   - Proper heading hierarchy
   - Clear typography for readability

### Template Sections

```
┌─────────────────────────────┐
│  Header with Gradient       │
│  (Status Emoji + Title)     │
├─────────────────────────────┤
│  Status Box                 │
│  (Emoji, Title, Description)│
├─────────────────────────────┤
│  Info Grid (2 columns)      │
│  - Order ID                 │
│  - Order Total              │
│  - Status Info              │
├─────────────────────────────┤
│  Order Items Table          │
│  (Product, Qty, Total)      │
├─────────────────────────────┤
│  Footer with Branding       │
└─────────────────────────────┘
```

---

## 🔧 Cloud Functions Implementation

### File Locations

1. **Email Service:** `functions/email-service.ts`
   - Contains email transporter configuration
   - Implements email sending functions
   - Handles HTML template generation

2. **Delivery Confirmation:** `functions/delivery-confirmation.ts`
   - Listens to order status changes
   - Triggers email notifications
   - Manages error handling

### Function Flow

```
Order Document Updated
    ↓
onOrderStatusUpdated Trigger
    ↓
Check Status Change
    ↓
For ALL Status Changes:
  └→ sendOrderStatusUpdateEmail()
       ↓
       Transporter sends via Zoho SMTP
       ↓
       Email delivered to admin

For 'placed' → 'confirmed':
  └→ sendOrderConfirmationEmail() [Additional detailed email]
```

### Error Handling

- Email failures do NOT block order updates
- Errors are logged but don't throw exceptions
- Admin notified of email sending issues in logs
- Graceful degradation if credentials missing

---

## 🚀 Deployment Steps

### 1. Set Environment Variables

```bash
# In Firebase Console > Functions > Runtime environment variables
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=your_zoho_password
ADMIN_EMAIL=admin@rajasthanpustaksadan.com
```

Or in local `.env.local` file:
```
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=your_zoho_password
ADMIN_EMAIL=admin@rajasthanpustaksadan.com
```

### 2. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 3. Test Email Sending

```bash
# Create a test order
# Update order status to trigger email
# Check admin email inbox
```

---

## 📊 Email Template Customization

### Change Colors

Edit the status colors in `sendOrderStatusUpdateEmail()`:

```typescript
const statusConfig: { [key: string]: { emoji: string; title: string; color: string; description: string } } = {
    'shipped': { emoji: '🚚', title: 'Order Shipped', color: '#9b59b6', description: '...' },
    // Add more or modify colors here
};
```

### Modify Template Content

1. Open `functions/email-service.ts`
2. Find the `html` property in `mailOptions`
3. Edit the HTML/CSS structure
4. Ensure responsive design is maintained

### Add Branding

- Change company name: "RPS Rajasthan Pustak Sadan"
- Update address/contact info in footer
- Modify logo/branding in header

---

## 🧪 Testing

### Local Testing

```bash
# Test with emulator
firebase emulators:start

# Trigger order status change
# Check emulator logs for email function execution
```

### Production Testing

```bash
# Create test order via app
# Change status in Firestore
# Verify email delivery in inbox
# Check Cloud Functions logs
```

### Test Cases

- [ ] Order placed → Email sent
- [ ] Order confirmed → Email sent with detailed template
- [ ] Order packed → Email sent
- [ ] Order shipped → Email sent
- [ ] Order out for delivery → Email sent
- [ ] Order delivered → Email sent
- [ ] Order cancelled → Email sent
- [ ] Email credentials invalid → Error logged, no crash
- [ ] Admin email missing → Warning logged
- [ ] Multiple status changes → Multiple emails sent

---

## 📝 Email Content Checklist

Each email includes:

✅ **Header**
- Emoji indicator
- Status title
- Company branding

✅ **Order Information**
- Order ID
- Order date/time
- Order total amount
- Previous and current status

✅ **Order Items**
- Product names
- Quantities
- Unit prices
- Line totals
- Grand total

✅ **Delivery Details** (if applicable)
- Recipient name
- Address lines
- City/State/Pincode
- Phone number

✅ **Payment Information**
- Payment status
- Payment method

✅ **Footer**
- Company name
- Location
- Disclaimer
- "Do not reply" message

---

## 🔐 Security Notes

1. **Credentials Management**
   - Never commit passwords to repository
   - Use Firebase environment variables
   - Rotate passwords regularly

2. **Email Validation**
   - Verify admin email is set before sending
   - Validate order data structure
   - Handle missing data gracefully

3. **Rate Limiting**
   - Firebase Cloud Functions have rate limits
   - Email sending may be throttled at scale
   - Monitor function execution logs

---

## 📞 Troubleshooting

### Issue: Emails not sending

**Solution 1:** Check credentials
```bash
# Verify EMAIL_USER and EMAIL_PASS in Firebase Console
# Test credentials with Zoho Mail webmail
```

**Solution 2:** Check firewall/port
```
- Ensure port 465 is open
- Verify SSL/TLS is enabled
- Check network policies
```

**Solution 3:** Review logs
```bash
firebase functions:log
# Look for error messages from email service
```

### Issue: Emails going to spam

**Solution:**
- Add SPF/DKIM records for domain
- Verify sender email in Zoho Mail
- Test with mailtest.in or similar
- Check email header formatting

### Issue: Template not rendering

**Solution:**
- Check HTML syntax in email-service.ts
- Test with email client HTML preview
- Verify CSS is inline (no external stylesheets)
- Check for encoding issues

---

## 📈 Monitoring

### Firebase Cloud Functions Dashboard

1. Go to Firebase Console > Functions
2. Monitor:
   - Execution count
   - Error rate
   - Memory usage
   - Execution time

### Email Logs

Check function logs:
```bash
firebase functions:log --only onOrderStatusUpdated
```

---

## 🔄 Future Enhancements

- [ ] Send confirmation email to customer as well
- [ ] Add email preferences/unsubscribe option
- [ ] Implement email templates database
- [ ] Add attachment support (invoices, labels)
- [ ] Implement email scheduling
- [ ] Add analytics tracking for email opens
- [ ] Support multiple admin emails
- [ ] Add email retry logic for failed sends
- [ ] Implement email rate limiting per user
- [ ] Add SMS notifications as fallback

---

## Support

For issues or questions:
- Check Cloud Functions logs
- Review Zoho Mail settings
- Verify Firebase configuration
- Test with simplified order data

---

**Last Updated:** February 1, 2026
**Configuration:** Zoho Mail SMTP (smtp.zoho.in:465)
**Email:** rps@rajasthanpustaksadan.com
