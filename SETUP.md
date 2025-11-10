# AI Voice Copilot - Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the AI Voice Copilot for CarPlay application. Follow these steps to integrate LiveKit SDK, configure backend endpoints, and deploy the application.

---

## Prerequisites

- **Xcode**: 15.2 or later
- **iOS Deployment Target**: 17.2+
- **Apple Developer Account**: Required for CarPlay entitlement
- **LiveKit Server**: Access to a LiveKit server instance
- **Backend API**: REST API endpoint for session management

---

## Step 1: Clone and Open Project

```bash
git clone https://github.com/jjeremycai/ai-voice-copilot-carplay.git
cd ai-voice-copilot-carplay
open CarPlaySwiftUI.xcodeproj
```

---

## Step 2: Add LiveKit Swift SDK

### Via Xcode (Recommended)

1. In Xcode, select **File → Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/livekit/client-swift
   ```
3. **Version Selection**:
   - Dependency Rule: Up to Next Major Version
   - Minimum Version: 2.0.0 (or latest stable)
4. Click **Add Package**
5. Select `CarPlaySwiftUI` as the target
6. Click **Add Package** to confirm

### Via Manual Package Management

If you prefer manual package management, add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/livekit/client-swift", from: "2.0.0")
]
```

### Verification

After adding the SDK:
1. Build the project (⌘B)
2. Verify no compilation errors in `Services/LiveKitService.swift`
3. The LiveKit import should resolve successfully

---

## Step 3: Configure Backend API

The application uses a centralized configuration system in `Services/Configuration.swift`.

### Option A: Environment Variables (Recommended)

Set environment variables for your backend API:

**For Development:**
```bash
export API_BASE_URL="https://api-dev.yourcompany.com/v1"
```

**For Production:**
```bash
export API_BASE_URL="https://api.yourcompany.com/v1"
```

**In Xcode:**
1. Select your scheme → **Edit Scheme...**
2. Go to **Run → Arguments**
3. Add environment variables:
   - Name: `API_BASE_URL`
   - Value: `https://api-dev.yourcompany.com/v1`

### Option B: Modify Configuration.swift

Edit `Services/Configuration.swift` directly:

```swift
var apiBaseURL: String {
    switch Environment.current {
    case .development:
        return "https://api-dev.yourcompany.com/v1"
    case .staging:
        return "https://api-staging.yourcompany.com/v1"
    case .production:
        return "https://api.yourcompany.com/v1"
    }
}
```

### Required API Endpoints

Your backend must implement these endpoints:

#### 1. Start Session
- **Endpoint**: `POST /v1/sessions/start`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "context": "carplay" | "phone"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "session_id": "uuid",
    "livekit_url": "wss://your-livekit-server.com",
    "livekit_token": "jwt-token",
    "room_name": "room-name"
  }
  ```

#### 2. End Session
- **Endpoint**: `POST /v1/sessions/end`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "session_id": "uuid"
  }
  ```
- **Response**: `204 No Content`

#### 3. Log Turn
- **Endpoint**: `POST /v1/sessions/:session_id/turn`
- **Headers**: `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "speaker": "user" | "assistant",
    "text": "transcript text",
    "timestamp": "2024-01-01T12:00:00Z"
  }
  ```
- **Response**: `200 OK`

#### 4. Fetch Sessions
- **Endpoint**: `GET /v1/sessions`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: `200 OK`
  ```json
  [
    {
      "id": "uuid",
      "title": "Session Title",
      "summary_snippet": "Brief summary...",
      "started_at": "2024-01-01T12:00:00Z",
      "ended_at": "2024-01-01T12:30:00Z"
    }
  ]
  ```

#### 5. Fetch Session Detail
- **Endpoint**: `GET /v1/sessions/:session_id`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: `200 OK`
  ```json
  {
    "summary": {
      "key_points": ["point1", "point2"],
      "action_items": ["action1"],
      "duration_seconds": 1800
    },
    "turns": [
      {
        "speaker": "user",
        "text": "Hello",
        "timestamp": "2024-01-01T12:00:00Z"
      }
    ]
  }
  ```

#### 6. Delete Session
- **Endpoint**: `DELETE /v1/sessions/:session_id`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: `204 No Content`

#### 7. Delete All Sessions
- **Endpoint**: `DELETE /v1/sessions`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: `204 No Content`

#### 8. Authentication - Login
- **Endpoint**: `POST /v1/auth/login`
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "token": "jwt-token",
    "expires_at": "2024-01-02T12:00:00Z"
  }
  ```

#### 9. Authentication - Refresh
- **Endpoint**: `POST /v1/auth/refresh`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: `200 OK`
  ```json
  {
    "token": "new-jwt-token",
    "expires_at": "2024-01-02T12:00:00Z"
  }
  ```

---

## Step 4: Configure LiveKit Server

### Server Requirements

- LiveKit Server version 1.0.0+
- WebRTC support enabled
- Token-based authentication configured

### LiveKit Token Generation

Your backend must generate LiveKit tokens with:
- **Room Name**: Unique per session
- **Participant Identity**: User ID or session ID
- **Permissions**:
  - `canPublish: true` (for user microphone)
  - `canSubscribe: true` (for assistant audio)
- **Expiration**: Match session duration + buffer

Example token generation (Node.js):
```javascript
const { AccessToken } = require('livekit-server-sdk');

function generateToken(sessionId, userId) {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET,
    {
      identity: userId,
      name: `User ${userId}`,
    }
  );

  token.addGrant({
    room: sessionId,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
  });

  return token.toJwt();
}
```

---

## Step 5: Request CarPlay Entitlement

### Apple Developer Portal

1. **Log in** to [Apple Developer Portal](https://developer.apple.com)
2. Go to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID
4. **Enable CarPlay Communication** capability
5. **Submit Request** to Apple
6. **Wait for Approval** (typically 1-2 weeks)

### After Approval

1. Download updated provisioning profiles
2. In Xcode, refresh provisioning profiles:
   - **Xcode → Settings → Accounts**
   - Select your team → **Download Manual Profiles**
3. Rebuild the project

---

## Step 6: Development Testing

### Without Backend (Local Development)

For local testing without a backend:

```swift
// In your app startup (e.g., AppDelegate or App struct)
AuthService.shared.setToken("dev-token-12345")
```

### With Backend (Integration Testing)

1. **Start Backend Server**
2. **Configure API URL** (see Step 3)
3. **Run App** in Simulator or Device
4. **Test Authentication**:
   - Use login screen or set token directly
5. **Test Call Flow**:
   - Initiate call from home screen
   - Verify LiveKit connection
   - Test audio streaming

### CarPlay Testing

#### In Simulator:
1. **Enable CarPlay Simulator**:
   - I/O → External Displays → CarPlay
2. **Test UI**:
   - Verify "Talk to Assistant" button appears
   - Test call initiation from CarPlay
3. **Verify Audio Routing**:
   - Audio should route to CarPlay output

#### In Vehicle:
1. Connect iPhone via Lightning/USB-C or wireless
2. Open CarPlay on vehicle display
3. Locate AI Voice Copilot app
4. Test full call flow

---

## Step 7: Run Tests

### Unit Tests

```bash
xcodebuild test \
  -scheme CarPlaySwiftUI \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or in Xcode: **Product → Test** (⌘U)

### Test Coverage

Current test coverage includes:
- ✅ CallManager
- ✅ AssistantCallCoordinator
- ✅ SessionLogger
- ✅ AuthService

---

## Step 8: Production Deployment

### Pre-Deployment Checklist

- [ ] LiveKit SDK integrated and tested
- [ ] Backend API connected and verified
- [ ] CarPlay entitlement approved
- [ ] All unit tests passing
- [ ] End-to-end call flow tested
- [ ] Production API URLs configured
- [ ] Authentication working
- [ ] Error handling tested
- [ ] Performance validated

### Build Configuration

1. **Select Release Scheme**:
   - Product → Scheme → Edit Scheme
   - Set Build Configuration to "Release"

2. **Update API URLs**:
   - Verify production URLs in Configuration.swift
   - Remove development tokens

3. **Archive and Submit**:
   - Product → Archive
   - Upload to App Store Connect
   - Submit for review

---

## Configuration Reference

### Configuration.swift

The centralized configuration file manages:
- API base URLs per environment
- Authentication endpoints
- Logging preferences
- Environment detection

### Environment Detection

```swift
enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}
```

### Print Configuration

For debugging:
```swift
Configuration.shared.printConfiguration()
```

Output:
```
================================================
AI Voice Copilot Configuration
================================================
Environment: development
API Base URL: https://api-dev.example.com/v1
Auth Login URL: https://api-dev.example.com/v1/auth/login
Logging Enabled: true
================================================
```

---

## Troubleshooting

### LiveKit SDK Not Found

**Error**: `No such module 'LiveKit'`

**Solution**:
1. Verify package is added: File → Add Package Dependencies
2. Clean build folder: Product → Clean Build Folder (⌘⇧K)
3. Reset package cache: File → Packages → Reset Package Caches
4. Rebuild project (⌘B)

### Backend Connection Fails

**Error**: API requests fail with network error

**Solution**:
1. Verify API_BASE_URL is set correctly
2. Check backend server is running
3. Test endpoint with curl:
   ```bash
   curl -X POST https://api-dev.yourcompany.com/v1/sessions/start \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer test-token" \
     -d '{"context":"phone"}'
   ```
4. Enable verbose logging in Configuration.swift

### CarPlay Not Appearing

**Error**: App doesn't show in CarPlay

**Solution**:
1. Verify CarPlay entitlement is approved by Apple
2. Check entitlements file includes:
   ```xml
   <key>com.apple.developer.carplay-communication</key>
   <true/>
   ```
3. Update provisioning profiles
4. Clean and rebuild project
5. Test on physical device connected to CarPlay

### Authentication Fails

**Error**: 401 Unauthorized responses

**Solution**:
1. Verify token is set: `AuthService.shared.authToken`
2. Check token expiration
3. Test login endpoint:
   ```swift
   let token = try await AuthService.shared.login(
       email: "test@example.com",
       password: "password"
   )
   ```
4. Verify backend returns correct response format

---

## Additional Resources

### Documentation
- [HANDOFF.md](HANDOFF.md) - Engineering handoff document
- [MASTER_SPEC.md](Documentation/MASTER_SPEC.md) - Complete specification
- [IMPLEMENTATION_STATUS.md](Documentation/IMPLEMENTATION_STATUS.md) - Implementation tracking

### External Documentation
- [LiveKit Swift SDK](https://github.com/livekit/client-swift)
- [LiveKit Server](https://docs.livekit.io/home/)
- [CallKit Documentation](https://developer.apple.com/documentation/callkit)
- [CarPlay Guidelines](https://developer.apple.com/carplay/)

---

## Support

For issues or questions:
1. Check [HANDOFF.md](HANDOFF.md) for known issues
2. Review [FIXES_APPLIED.md](Documentation/FIXES_APPLIED.md) for resolved issues
3. Open an issue on GitHub

---

**Setup complete! Your AI Voice Copilot for CarPlay is ready for development and testing.**
