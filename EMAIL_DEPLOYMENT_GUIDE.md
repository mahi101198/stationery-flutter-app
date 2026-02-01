# 🚀 Quick Deployment & Testing Guide

## Step-by-Step Deployment

### 1️⃣ Update Environment Variables

**File**: [functions/.env](functions/.env)

```bash
# Open the .env file
# Update these values:
EMAIL_USER=rps@rajasthanpustaksadan.com
EMAIL_PASS=<YOUR_ZOHO_PASSWORD>  # Add your Zoho password here
ADMIN_EMAIL=mk7823807402@gmail.com  # Where you want to receive order notifications
SMTP_HOST=smtp.zoho.in
SMTP_PORT=465
SMTP_SECURE=true
```

**To get your Zoho password:**
1. Go to [zoho.com](https://www.zoho.com)
2. Sign in to your Zoho Mail account
3. Go to Settings → Connected Apps (if using app password)
4. Or use your main Zoho account password

---

### 2️⃣ Install Dependencies (if needed)

```powershell
cd d:\backup rps\rps-stationery-main\functions
npm install
```

**Expected packages:**
- nodemailer (email sending)
- firebase-functions
- firebase-admin
- typescript

---

### 3️⃣ Deploy Cloud Functions

```powershell
# From project root
firebase deploy --only functions

# Or deploy just this function
firebase deploy --only functions:onOrderStatusUpdated
```

**Expected output:**
```
✔ functions[onOrderStatusUpdated(asia-south1)]: Successful update
Function URL: https://asia-south1-rps-statationary-jaipur.cloudfunctions.net/onOrderStatusUpdated
```

---

### 4️⃣ Verify Deployment

```powershell
# List deployed functions
firebase functions:list

# Check specific function
firebase functions:log --function=onOrderStatusUpdated

# View real-time logs
firebase functions:log --tail
```

---

## 🧪 Testing the Email System

### Method 1: Using Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Navigate to Firestore Database → `orders` collection
3. Find a test order (or create one)
4. Update the `status` field:
   - From: `placed`
   - To: `confirmed`
5. Click Update
6. Check your email in 30-60 seconds

### Method 2: Using Cloud Firestore Emulator (Local Testing)

```powershell
# Start Firebase emulator
firebase emulators:start

# In another terminal, run test script
node test-email.js
```

### Method 3: Direct Cloud Function Call

```bash
# Get your function URL from firebase deploy output
# Then call it manually or trigger via API

# Example: Using curl
curl -X POST https://asia-south1-rps-statationary-jaipur.cloudfunctions.net/onOrderStatusUpdated \
  -H "Content-Type: application/json" \
  -d '{"orderId":"test-order-123","status":"confirmed"}'
```

---

## 📧 Expected Emails

### Email 1: When Status Changes to "confirmed"

**Subject**: 📦 New Order Confirmed: #ORD-2026-001234
**Recipient**: ADMIN_EMAIL
**Template**: Order Confirmation Email
**Color**: Purple gradient header
**Contains**:
- Order ID and total amount
- Itemized products list
- Delivery address
- Payment information
- Professional HTML formatting

### Email 2: For ANY Status Change

**Subject**: [Emoji] Order Status Update: #ORD-2026-001234 - [Status Name]
**Recipient**: ADMIN_EMAIL
**Template**: Status Update Email
**Color**: Status-specific color
**Contains**:
- Status emoji (📝, ✅, 📦, 🚚, 📍, 🎉, etc.)
- Previous and current status
- Order items table
- Updated timestamp
- Company footer

---

## ✅ Troubleshooting

### Issue 1: Email Not Received

**Check these in order:**

1. **Check Cloud Function Logs**
```powershell
firebase functions:log

# Look for:
# ✅ "📧 Order status update email sent"
# ❌ "Error sending order status update email"
```

2. **Check Email Credentials**
```powershell
# In functions/.env
# EMAIL_USER=rps@rajasthanpustaksadan.com
# EMAIL_PASS=your_actual_password
# Don't use app passwords - use main Zoho password
```

3. **Check SMTP Connection**
```powershell
# Test SMTP connection with telnet (Windows)
telnet smtp.zoho.in 465
# Should connect without errors
```

4. **Check Spam/Junk Folder**
```
Gmail: Check "All Mail" and mark as "Not Spam"
Outlook: Check Junk folder
```

---

### Issue 2: Authentication Failed

**Error**: `550 5.1.1 user not found`

**Solution**:
1. Verify email address is correct
2. Check Zoho account exists and is active
3. Verify Zoho account has "SMTP Enabled" in settings
4. Use main account password (not app-specific password)

**Steps**:
```
1. Go to zoho.com → Sign In
2. Settings → Security → Password
3. Note: You may need to generate App Password in Zoho
4. Update EMAIL_PASS in .env
5. Redeploy: firebase deploy --only functions
```

---

### Issue 3: Connection Timeout

**Error**: `connect ETIMEDOUT smtp.zoho.in:465`

**Solutions**:
1. Check internet connection
2. Verify port 465 is not blocked by firewall
3. Try connecting to smtp.zoho.com instead
4. Check if VPN is interfering

**Test connection:**
```powershell
# PowerShell
Test-NetConnection smtp.zoho.in -Port 465

# Should show: TcpTestSucceeded: True
```

---

### Issue 4: Function Not Triggering

**Check**:
1. Is function deployed?
   ```powershell
   firebase functions:list
   ```

2. Does function have proper permissions?
   - Go to Firebase Console → Cloud Functions
   - Check "Logs" for deployment errors

3. Is order data structure correct?
   - Order must have `status` field
   - Ensure `userId` is populated

4. Check function logs:
   ```powershell
   firebase functions:log --tail
   ```

---

## 🔍 Monitoring & Debugging

### Enable Debug Logging

In [functions/delivery-confirmation.ts](functions/delivery-confirmation.ts), the logging is already set:

```typescript
logger.info(`Order ${orderId} status changed: ${beforeStatus} → ${afterStatus}`);
logger.info(`📧 Order ${orderId} status changed to ${afterStatus}, sending email`);
logger.error(`Error sending email:`, error);
```

### View Logs in Real-time

```powershell
# Live tail of all function logs
firebase functions:log --tail

# Filter by function
firebase functions:log --function=onOrderStatusUpdated

# View last 100 lines
firebase functions:log --limit=100
```

### Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Cloud Functions → onOrderStatusUpdated
4. Click "Logs" tab
5. Filter by:
   - Time range
   - Log level (Info, Warning, Error)
   - Search keywords

---

## 📊 Testing Checklist

- [ ] `.env` file updated with EMAIL_PASS
- [ ] `npm install` completed in functions folder
- [ ] `firebase deploy --only functions` successful
- [ ] Function appears in `firebase functions:list`
- [ ] Created test order or used existing order
- [ ] Updated order status to "confirmed"
- [ ] Checked email inbox after 1-2 minutes
- [ ] Email subject matches pattern: `[Emoji] Order Status Update: #...`
- [ ] Email contains order details and items table
- [ ] Email HTML renders properly in email client
- [ ] Checked cloud function logs for errors
- [ ] Tested another status change (e.g., to "packed")

---

## 🎯 Success Criteria

✅ **Email System is Working When:**

1. Function deploys without errors
2. Log shows: `"📧 Order status updated email sent: [message-id]"`
3. Email arrives in admin inbox within 2 minutes
4. Email subject includes order ID
5. Email body shows correct order details
6. HTML template renders with colors and styling
7. No errors in cloud function logs

❌ **If Any of Above Missing:**

1. Check `.env` EMAIL_PASS
2. Verify Zoho account credentials
3. Check cloud function logs
4. Verify order data structure
5. Test SMTP connection manually

---

## 📝 Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `ADMIN_EMAIL not set` | Missing env var | Add ADMIN_EMAIL to .env |
| `Email credentials not set` | Missing EMAIL_USER or PASSWORD | Add both to .env |
| `550 5.1.1 user not found` | Wrong email or account inactive | Verify Zoho account |
| `connection timeout` | Network or port blocked | Check port 465, firewall |
| `auth failed` | Wrong password | Use main Zoho password |
| `transporter not configured` | Email-service import failed | Check npm install |

---

## 🔐 Security Reminders

⚠️ **IMPORTANT:**
- ❌ Never commit `.env` to GitHub
- ❌ Never share EMAIL_PASS in messages
- ✅ Use `.gitignore` to exclude `.env`
- ✅ Rotate password every 90 days
- ✅ Use strong password (min 12 chars)
- ✅ Enable 2FA on Zoho account

---

## 📞 Need Help?

**Firebase Issues?**
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Console](https://console.firebase.google.com)

**Email Issues?**
- [Zoho Mail Settings](https://www.zoho.com/mail)
- [Nodemailer Docs](https://nodemailer.com)

**Check Logs First!**
```powershell
firebase functions:log --tail
# Most issues are visible in logs
```

---

**Status**: 🟢 Ready to Deploy
**Last Updated**: February 1, 2026
