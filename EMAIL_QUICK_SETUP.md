# Email Configuration Quick Setup Guide

## ⚡ Quick Start (5 minutes)

### Step 1: Set Environment Variables in Firebase

1. Go to **Firebase Console** → Your Project
2. Navigate to **Functions** → Click on function name → **Runtime environment variables**
3. Add these variables:

```
EMAIL_USER = rps@rajasthanpustaksadan.com
EMAIL_PASS = <Your Zoho Mail Password>
ADMIN_EMAIL = <Your Admin Email Address>
```

### Step 2: Deploy Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### Step 3: Test

1. Create a test order in your app
2. Update order status to "confirmed"
3. Check your admin email inbox
4. You should receive a beautifully formatted email

---

## 🎨 What You Get

### Email Features

✨ **Professional Design**
- Gradient headers with status emojis
- Color-coded by order status
- Fully responsive (works on mobile)
- Modern, attractive layout

📊 **Order Details**
- Order ID and date
- Itemized list with prices
- Delivery address
- Payment information
- Total amount

🚀 **Automated Triggers**
Emails sent automatically for:
- Order placed 📝
- Order confirmed ✅
- Order packed 📦
- Order shipped 🚚
- Out for delivery 📍
- Order delivered 🎉
- Order cancelled ❌
- Refunds processed 💰

---

## 📋 Email Configuration Files

### Modified Files

1. **`functions/email-service.ts`**
   - Updated SMTP configuration (Zoho Mail)
   - New professional HTML templates
   - Added `sendOrderStatusUpdateEmail()` function

2. **`functions/delivery-confirmation.ts`**
   - Updated to trigger emails on all status changes
   - Better error handling
   - Logs for monitoring

---

## 🔧 SMTP Configuration

```
Host:     smtp.zoho.in
Port:     465
Security: SSL/TLS
Auth:     rps@rajasthanpustaksadan.com
```

**Why Zoho?**
- Reliable Indian email service
- Good for business use
- Better deliverability than generic SMTP
- Professional email from custom domain

---

## 📧 Email Template Preview

### Header Section
```
🚚 Order Shipped
Order #1234567890
```

### Content Sections
- Order ID & Date
- 4-column items table (Product, Qty, Price, Total)
- Delivery address
- Payment status & method
- Timestamp

### Colors by Status
- Placed: 🔵 Blue
- Confirmed: 🟣 Purple
- Packed: 🟠 Orange
- Shipped: 🟣 Purple
- Out for Delivery: 🔴 Red
- Delivered: 🟢 Green
- Cancelled: 🔴 Dark Red
- Refunded: 🟢 Teal

---

## ✅ Verification Checklist

- [ ] Environment variables set in Firebase
- [ ] Functions deployed successfully
- [ ] Created test order
- [ ] Changed order status
- [ ] Received email in admin inbox
- [ ] Email displays correctly
- [ ] All links and formatting work
- [ ] Email not in spam folder

---

## 🆘 If Emails Don't Work

1. **Check credentials**
   ```bash
   # Verify in Firebase Console > Functions > Runtime environment variables
   # Make sure EMAIL_USER and EMAIL_PASS are correct
   ```

2. **Check logs**
   ```bash
   firebase functions:log
   ```

3. **Verify port 465 is accessible**
   - Test with: `telnet smtp.zoho.in 465`

4. **Check email is valid**
   - Sign in to Zoho Mail to verify account works

---

## 📊 Email Statistics (After Deployment)

In Firebase Console → Functions:
- **Execution count:** Shows number of emails sent
- **Error rate:** Monitor for issues
- **Execution time:** Usually 2-5 seconds per email
- **Memory:** Minimal usage

---

## 🎯 Next Steps

1. ✅ Set environment variables
2. ✅ Deploy functions
3. ✅ Test with order
4. ✅ Monitor email delivery
5. ✅ Customize template (optional)
6. ✅ Add customer emails (future enhancement)

---

## 📞 Support & Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Emails not sending | Check environment variables are set |
| Emails in spam | Check sender reputation, add SPF/DKIM records |
| Wrong email formatting | Clear browser cache and re-test |
| Function timeout | Check log for specific error |
| Password incorrect | Verify Zoho password (not app password) |

### Debug Steps

1. Open Firebase Console
2. Go to Functions → onOrderStatusUpdated
3. Click on "Logs" tab
4. Look for error messages
5. Check EMAIL_USER and EMAIL_PASS in environment

---

## 🎨 Customization

### Change Email Address

In `functions/email-service.ts`:
```typescript
from: `"RPS Rajasthan Pustak Sadan" <${process.env.EMAIL_USER}>`,
```

### Change Colors

Find the `statusConfig` object and modify color hex codes:
```typescript
'shipped': { color: '#9b59b6', ... }, // Change #9b59b6 to any color
```

### Change Company Name

Search for "RPS Rajasthan Pustak Sadan" and replace throughout:
- In email header
- In footer
- In subject lines

---

## 📚 Additional Resources

- Full documentation: [EMAIL_SETUP_DOCUMENTATION.md](EMAIL_SETUP_DOCUMENTATION.md)
- Zoho Mail: https://mail.zoho.in
- Firebase Functions: https://firebase.google.com/functions
- HTML Email Best Practices: https://www.campaignmonitor.com/guides/

---

**Status:** ✅ Ready for Production
**Last Updated:** February 1, 2026
**Email Service:** Zoho Mail (smtp.zoho.in:465 SSL)
