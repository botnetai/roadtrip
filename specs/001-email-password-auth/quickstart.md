# Quickstart: Email & Password Authentication

**Feature**: 001-email-password-auth
**Branch**: `001-email-password-auth`

## Prerequisites

- Node.js 20+
- PostgreSQL (or SQLite for local dev)
- Xcode 15+ with iOS 17.2 SDK
- Railway account (for deployment)

## Backend Setup

### 1. Install new dependencies

```bash
cd backend
npm install bcrypt resend
```

### 2. Environment variables

Add to `.env`:

```env
# Email service (Resend)
RESEND_API_KEY=re_xxxxxxxxx

# Password reset
PASSWORD_RESET_URL=https://yourapp.com/reset-password
```

### 3. Database migration

The migration runs automatically on server start via `database.js`. New tables:
- `users` - email/password accounts
- `password_reset_tokens` - recovery tokens

### 4. Test locally

```bash
npm run dev
```

Test registration:
```bash
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "TestPassword123"}'
```

Test login:
```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "TestPassword123"}'
```

## iOS Setup

### 1. Add new endpoint URLs

In `Services/Configuration.swift`, add:

```swift
var authRegisterURL: String { "\(baseURL)/v1/auth/register" }
var authPasswordResetRequestURL: String { "\(baseURL)/v1/auth/password/reset-request" }
var authPasswordResetURL: String { "\(baseURL)/v1/auth/password/reset" }
```

### 2. Build and run

```bash
open Roadtrip.xcodeproj
# Run on simulator or device
```

### 3. Test email auth flow

1. Open app → Settings → Account section
2. Tap "Sign in with Email"
3. Register new account or login
4. Test password reset flow

## Deployment

### Railway

1. Push changes to branch
2. Railway auto-deploys from main
3. Add `RESEND_API_KEY` to Railway environment variables

### App Store

1. Build with Fastlane: `fastlane beta`
2. Submit to TestFlight
3. Test on real device before production release

## Verification Checklist

- [ ] Registration creates account and returns token
- [ ] Login validates credentials and returns token
- [ ] Invalid credentials return 401 (without revealing which field)
- [ ] Rate limiting kicks in after 5 failed attempts
- [ ] Password reset email sends within 5 minutes
- [ ] Reset token expires after 1 hour
- [ ] Used reset token cannot be reused
- [ ] iOS app shows both Sign in with Apple and Email options
- [ ] Sign in with Apple flow still works unchanged
- [ ] Guest users can upgrade to email account

## Troubleshooting

### "Email already exists" error
The email is already registered. Use login or password reset.

### Password reset email not received
1. Check spam folder
2. Verify `RESEND_API_KEY` is set
3. Check Resend dashboard for delivery status

### Rate limited
Wait 15 minutes or use a different IP for testing.

### iOS build fails
1. Clean build folder (Cmd+Shift+K)
2. Delete derived data
3. Re-run pod install if using CocoaPods
