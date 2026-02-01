# Cloud Functions Environment Variables Template

## Firebase Cloud Functions Configuration

Create a `.env.local` file in the `functions/` directory with the following variables:

```env
# ==========================================
# EMAIL CONFIGURATION - ZOHO MAIL SMTP
# ==========================================

# Zoho Mail SMTP User
# Email address to send emails from
EMAIL_USER=rps@rajasthanpustaksadan.com

# Zoho Mail SMTP Password
# Generated in Zoho Mail security settings
# Note: Use app-specific password if 2FA is enabled
EMAIL_PASS=your_zoho_mail_password_here

# Admin email address
# Where order notifications will be sent
ADMIN_EMAIL=admin@rajasthanpustaksadan.com


# ==========================================
# ADDITIONAL CONFIGURATION (Optional)
# ==========================================

# Admin name (for personalized emails)
ADMIN_NAME=Rajasthan Pustak Sadan Admin

# Business email
BUSINESS_EMAIL=rps@rajasthanpustaksadan.com

# Business phone
BUSINESS_PHONE=+91-XXXXXXXXXX

# Business address
BUSINESS_ADDRESS=Rajasthan, India
```

---

## 🔒 How to Set in Firebase Console

### Method 1: Firebase Console UI

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Functions** (in left sidebar)
4. Click on the function name (e.g., `onOrderStatusUpdated`)
5. Click on the **Runtime** tab
6. Scroll to **Runtime environment variables**
7. Add each variable:
   - **Name:** `EMAIL_USER`
   - **Value:** `rps@rajasthanpustaksadan.com`
8. Click **Add**
9. Repeat for other variables
10. Click **Deploy** to save

### Method 2: Firebase CLI

```bash
cd functions

# Install Firebase CLI if not already
npm install -g firebase-tools

# Login to Firebase
firebase login

# Set environment variables
firebase functions:config:set \
  email.user="rps@rajasthanpustaksadan.com" \
  email.pass="your_zoho_password" \
  email.admin="admin@rajasthanpustaksadan.com"

# Deploy
firebase deploy --only functions
```

### Method 3: functions/.env.local

Create file `functions/.env.local`:

```env
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=your_password
ADMIN_EMAIL=admin@rajasthanpustaksadan.com
```

Then in `functions/email-service.ts`, access with:
```typescript
process.env.EMAIL_USER
process.env.EMAIL_PASS
process.env.ADMIN_EMAIL
```

---

## 📋 Zoho Mail Setup Steps

### 1. Create Zoho Mail Account

- Go to https://mail.zoho.in
- Sign up or log in
- Set up email: `rps@rajasthanpustaksadan.com`

### 2. Generate App Password (if 2FA enabled)

1. Log in to Zoho Mail
2. Go to **Settings** → **Security**
3. Scroll to **App Passwords**
4. Select **Other** as app type
5. Generate password
6. Use this password in EMAIL_PASS

### 3. Enable SMTP

1. In Zoho Mail Settings
2. Go to **Other Settings** → **Protocol Settings**
3. Enable **IMAP/SMTP**
4. Note the SMTP settings:
   - **Server:** smtp.zoho.in
   - **Port:** 465 (SSL)

### 4. Test Connection

```bash
# Install telnet or use online tool
telnet smtp.zoho.in 465

# Should connect successfully
```

---

## 🔐 Security Best Practices

### DO's ✅
- ✅ Use strong passwords
- ✅ Keep credentials in environment variables
- ✅ Rotate passwords regularly
- ✅ Use app-specific passwords for 2FA
- ✅ Monitor function logs for errors
- ✅ Test in staging before production

### DON'Ts ❌
- ❌ Never commit passwords to git
- ❌ Never hardcode credentials in functions
- ❌ Never share passwords in messages
- ❌ Never use same password as account login
- ❌ Never disable 2FA
- ❌ Never expose logs publicly

---

## 🧪 Test Configuration

### Test Script

Save as `functions/test-email.ts`:

```typescript
import { sendOrderStatusUpdateEmail } from './email-service.js';

// Test data
const testOrder = {
  orderId: 'TEST-001',
  items: [
    { name: 'Notebook', quantity: 2, price: 100 },
    { name: 'Pen Set', quantity: 1, price: 200 }
  ],
  pricing: { total: 400 },
  paymentStatus: 'successful',
  paymentMode: 'upi',
};

// Send test email
await sendOrderStatusUpdateEmail(
  'TEST-001',
  testOrder,
  'placed',
  'confirmed'
);

console.log('✅ Test email sent!');
```

### Run Test

```bash
cd functions
npm run build
npm run test
```

---

## 📊 Environment Variable Validation

Add this to your functions to validate configuration on startup:

```typescript
function validateEmailConfig() {
  const required = ['EMAIL_USER', 'EMAIL_PASS', 'ADMIN_EMAIL'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.warn('⚠️ Missing environment variables:', missing);
    console.warn('Email notifications will not work until these are set');
  } else {
    console.log('✅ Email configuration validated');
  }
}

// Call on function initialization
validateEmailConfig();
```

---

## 🔄 Updating Credentials

### If Zoho Password Changes

1. Go to Firebase Console
2. Find the Functions section
3. Update the `EMAIL_PASS` environment variable
4. Deploy functions again

### If Admin Email Changes

1. Update `ADMIN_EMAIL` environment variable
2. Deploy functions again
3. Test with a status change

---

## 📚 Environment Variables Reference

| Variable | Required | Type | Example | Purpose |
|----------|----------|------|---------|---------|
| EMAIL_USER | ✅ Yes | String | rps@rajasthanpustaksadan.com | SMTP authentication username |
| EMAIL_PASS | ✅ Yes | String | secure_password_123 | SMTP authentication password |
| ADMIN_EMAIL | ✅ Yes | String | admin@example.com | Email to receive notifications |
| ADMIN_NAME | ❌ No | String | Admin Name | For personalized emails |
| BUSINESS_EMAIL | ❌ No | String | business@example.com | Company email |
| BUSINESS_PHONE | ❌ No | String | +91-XXXXXXXXXX | Contact phone |
| BUSINESS_ADDRESS | ❌ No | String | Rajasthan, India | Business location |

---

## ✅ Verification Checklist

- [ ] Zoho Mail account created
- [ ] SMTP enabled in Zoho Mail
- [ ] App password generated (if 2FA)
- [ ] EMAIL_USER set correctly
- [ ] EMAIL_PASS set correctly
- [ ] ADMIN_EMAIL set correctly
- [ ] Functions deployed
- [ ] Test email sent
- [ ] Email received in inbox
- [ ] Email formatting correct

---

## 🆘 Troubleshooting

### Error: "Invalid credentials"
```
→ Check EMAIL_USER and EMAIL_PASS are correct
→ Test login at https://mail.zoho.in manually
→ Generate new app password if 2FA enabled
```

### Error: "Connection refused on port 465"
```
→ Verify firewall allows port 465 outbound
→ Check network connectivity
→ Test with: telnet smtp.zoho.in 465
```

### Error: "Variable not defined"
```
→ Ensure variable is set in Firebase Console
→ Check spelling (case-sensitive)
→ Redeploy functions after adding variable
```

### Email in spam folder
```
→ Add sender to contacts
→ Check Zoho sender reputation
→ Verify SPF/DKIM records
→ Check email headers
```

---

## 📖 Related Files

- Email service implementation: [functions/email-service.ts](functions/email-service.ts)
- Delivery confirmation trigger: [functions/delivery-confirmation.ts](functions/delivery-confirmation.ts)
- Full documentation: [EMAIL_SETUP_DOCUMENTATION.md](EMAIL_SETUP_DOCUMENTATION.md)
- Quick setup guide: [EMAIL_QUICK_SETUP.md](EMAIL_QUICK_SETUP.md)

---

**Last Updated:** February 1, 2026
**SMTP Provider:** Zoho Mail
**Configuration Status:** Ready for Production
