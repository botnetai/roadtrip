# Remaining Tasks - Action Plan

## Status: Build Configuration Complete ✅

All code is implemented and project files are configured. The following tasks require manual execution to verify and complete the integration.

---

## 1. Build & Test Verification ⏱️ 10 minutes

**Goal**: Prove that all 19 source files and 7 test files compile and execute.

### Steps:

#### 1a. Clean Build Folder
```
In Xcode:
⌘⇧K (Product → Clean Build Folder)
```

#### 1b. Build Main Target
```
⌘B (Product → Build)

Expected:
✅ Build succeeds
✅ 19 Swift files compiled
✅ LiveKit package resolved
✅ Zero errors

If errors occur:
- Check LiveKit package is fetched (File → Packages → Resolve Package Versions)
- Verify Xcode selected developer directory: sudo xcode-select -s /Applications/Xcode.app
```

#### 1c. Run Unit Tests
```
⌘U (Product → Test)

Expected:
✅ All tests compile
✅ 7 test files execute
✅ 16+ test cases run
✅ CarPlaySwiftUITests.swift
✅ MockCallKit.swift
✅ MockURLProtocol.swift
✅ CallManagerTests.swift
✅ AssistantCallCoordinatorTests.swift
✅ SessionLoggerTests.swift
✅ AuthServiceTests.swift

Test results should show:
- Test Suite 'CarPlaySwiftUITests.xctest' started
- Test Case '-[CallManagerTests testReportIncomingCall_Success]' passed
- Test Case '-[AssistantCallCoordinatorTests testStartCallFromPhone_Success]' passed
- ... (all tests)
- Test Suite 'CarPlaySwiftUITests.xctest' passed
```

#### Verification Checklist:
- [ ] Build completes without errors
- [ ] All 19 source files compile
- [ ] LiveKit module imports successfully
- [ ] Configuration.shared resolves
- [ ] All 7 test files compile
- [ ] All test cases execute
- [ ] Zero test failures

---

## 2. Backend Wiring ⏱️ 30 minutes

**Goal**: Connect to real backend API and verify request/response contracts.

### 2a. Set API Base URL

**Option A: Environment Variable (Recommended)**
```bash
# Add to your shell profile (~/.zshrc or ~/.bash_profile)
export API_BASE_URL="https://api.yourcompany.com/v1"

# Or in Xcode:
Edit Scheme → Run → Arguments → Environment Variables
Name: API_BASE_URL
Value: https://api.yourcompany.com/v1
```

**Option B: Direct Edit**
```swift
// Services/Configuration.swift (lines 20-30)
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

### 2b. Verify API Endpoints

Your backend must implement these 9 endpoints:

#### Authentication Endpoints
```
POST /auth/login
Request: { "email": "...", "password": "..." }
Response: { "token": "...", "expires_at": "2024-12-31T23:59:59Z" }

POST /auth/refresh
Headers: Authorization: Bearer <token>
Response: { "token": "...", "expires_at": "..." }
```

#### Session Endpoints
```
POST /sessions/start
Headers: Authorization: Bearer <token>
Request: { "context": "carplay" | "phone" }
Response: {
  "session_id": "uuid",
  "livekit_url": "wss://...",
  "livekit_token": "...",
  "room_name": "..."
}

POST /sessions/end
Headers: Authorization: Bearer <token>
Request: { "session_id": "uuid" }
Response: 204 No Content

POST /sessions/:id/turn
Headers: Authorization: Bearer <token>
Request: {
  "speaker": "user" | "assistant",
  "text": "...",
  "timestamp": "2024-01-09T12:00:00Z"
}
Response: 200 OK

GET /sessions
Headers: Authorization: Bearer <token>
Response: [{
  "id": "uuid",
  "title": "...",
  "summary_snippet": "...",
  "started_at": "2024-01-09T12:00:00Z",
  "ended_at": "2024-01-09T12:05:00Z"
}]

GET /sessions/:id
Headers: Authorization: Bearer <token>
Response: {
  "summary": {
    "title": "...",
    "summary": "...",
    "key_points": [...],
    "action_items": [...]
  },
  "turns": [{
    "speaker": "user",
    "text": "...",
    "timestamp": "..."
  }]
}

DELETE /sessions/:id
Headers: Authorization: Bearer <token>
Response: 204 No Content

DELETE /sessions
Headers: Authorization: Bearer <token>
Response: 204 No Content
```

#### Critical Notes:
- ✅ All JSON must use snake_case (e.g., `session_id`, not `sessionId`)
- ✅ Empty responses return 204 No Content (no JSON body)
- ✅ All timestamps in ISO 8601 format
- ✅ All authenticated endpoints require `Authorization: Bearer <token>` header

### 2c. Test Integration

**Manual Testing:**
```bash
# Test login
curl -X POST https://api.yourcompany.com/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Test session start (use token from above)
curl -X POST https://api.yourcompany.com/v1/sessions/start \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"context":"phone"}'
```

**In-App Testing:**
1. Run app in simulator
2. Complete onboarding
3. Try to start a call
4. Check Console for API request/response logs
5. Verify SessionLogger logs show successful requests

#### Verification Checklist:
- [ ] API base URL configured
- [ ] Authentication endpoints working
- [ ] All 9 endpoints return correct format
- [ ] Snake_case JSON confirmed
- [ ] Empty responses return 204
- [ ] Authorization headers accepted
- [ ] App can start/end sessions

---

## 3. LiveKit Verification ⏱️ 1 hour

**Goal**: Validate audio publish/subscribe behavior end-to-end.

### 3a. Verify Package Reference

The project already references LiveKit in project.pbxproj, but Xcode needs to fetch it:

```
In Xcode:
File → Packages → Resolve Package Versions
Wait for LiveKit to download

If package doesn't appear:
File → Add Package Dependencies
URL: https://github.com/livekit/client-swift
Version: 2.0.0 or later
Target: CarPlaySwiftUI
```

### 3b. Verify LiveKit Integration Code

Check that LiveKitService.swift is active:
```swift
// Line 8 should be uncommented:
import LiveKit

// Lines 37-166 should contain active (not commented) code:
- connect() method
- disconnect() method
- publishMicrophone() method
- subscribeToAssistantAudio() method
- RoomDelegate extension
```

### 3c. Set Up LiveKit Test Server

**Option A: LiveKit Cloud**
1. Sign up at https://livekit.io
2. Create a project
3. Get API credentials
4. Update backend to generate LiveKit tokens

**Option B: Self-Hosted**
```bash
docker run --rm -p 7880:7880 \
  -p 7881:7881 \
  -p 7882:7882/udp \
  livekit/livekit-server \
  --dev
```

### 3d. Test Audio Streaming

**Full Integration Test:**
1. Configure backend to return real LiveKit URL and token
2. Run app in simulator
3. Grant microphone permissions
4. Start a call
5. Monitor Console for LiveKit logs:
   ```
   LiveKit: Connected to room
   LiveKit: Publishing microphone
   LiveKit: Subscribed to assistant audio
   ```

**Test Checklist:**
- [ ] LiveKit package fetched successfully
- [ ] App builds with LiveKit import
- [ ] LiveKitService.connect() completes
- [ ] Microphone permission granted
- [ ] Audio track published
- [ ] Remote audio subscribed
- [ ] RoomDelegate callbacks fire
- [ ] Reconnection handling works

**Common Issues:**

**Issue: Build fails with "No such module 'LiveKit'"**
```
Solution:
1. File → Packages → Resolve Package Versions
2. Clean build folder (⌘⇧K)
3. Rebuild (⌘B)
```

**Issue: LiveKit connection fails**
```
Check:
1. Backend returns valid LiveKit URL and token
2. Token not expired
3. Room name matches
4. Network connectivity
5. Console logs for specific error
```

**Issue: Microphone not publishing**
```
Check:
1. Microphone permission granted (Settings → Privacy)
2. AVAudioSession configured correctly
3. LiveKitService.publishMicrophone() called
4. Console logs for audio track creation
```

---

## 4. Compliance Checks ⏱️ 2-3 weeks (waiting time)

**Goal**: Request CarPlay Communication entitlement and test on hardware.

### 4a. Request CarPlay Entitlement

**Steps:**
1. Go to https://developer.apple.com
2. Navigate to: Certificates, Identifiers & Profiles
3. Select: Identifiers → App IDs
4. Find: com.vanities.CarPlaySwiftUI (or your bundle ID)
5. Edit Capabilities
6. Enable: **CarPlay Communication**
7. Submit request with justification:
   ```
   App Purpose: AI voice assistant for hands-free operation
   Use Case: Users initiate voice calls to AI assistant via CarPlay
   Safety: Hands-free operation reduces distraction
   User Benefit: Safer way to interact with AI while driving
   ```

**Wait Time:**
- Apple typically reviews within 1-2 weeks
- You'll receive email notification

### 4b. Update Provisioning Profiles

**After Approval:**
1. Download updated provisioning profile
2. In Xcode: Settings → Accounts → Download Manual Profiles
3. Verify entitlement in .entitlements file:
   ```xml
   <key>com.apple.developer.carplay-communication</key>
   <true/>
   ```

### 4c. Test on CarPlay Simulator

**Steps:**
1. Run app in iOS Simulator
2. In Simulator: I/O → External Displays → CarPlay
3. CarPlay screen should appear
4. Verify: App icon appears in CarPlay
5. Tap: "Talk to Assistant" button
6. Verify: Call initiates properly

### 4d. Test on Physical Device

**Required:**
- CarPlay-enabled vehicle OR
- CarPlay-compatible head unit

**Steps:**
1. Connect iPhone to vehicle via USB
2. Enable CarPlay on vehicle screen
3. Verify app appears in CarPlay
4. Test "Talk to Assistant" flow
5. Verify audio routing to car speakers
6. Test hands-free operation

#### Verification Checklist:
- [ ] Entitlement requested from Apple
- [ ] Approval received (1-2 weeks)
- [ ] Provisioning profiles updated
- [ ] App appears in CarPlay simulator
- [ ] App appears on physical CarPlay
- [ ] "Talk to Assistant" button works
- [ ] Audio routes correctly
- [ ] CallKit integration works in car

---

## 5. QA Plan ⏱️ 4 hours

**Goal**: Comprehensive testing of all user flows and edge cases.

### 5a. CallKit Integration Tests

**Scenarios:**
- [ ] Incoming system call interrupts assistant call
- [ ] Assistant call interrupted by FaceTime
- [ ] Multiple rapid call attempts
- [ ] Call while app in background
- [ ] Call while phone locked
- [ ] Call from CarPlay, switch to phone
- [ ] Call from phone, switch to CarPlay

**Test Script:**
```
1. Start assistant call
2. Simulate incoming phone call (use Xcode → Debug → Simulate Background Fetch)
3. Verify: Assistant call ends gracefully
4. Verify: Session logged correctly
5. Verify: No crashes or hanging state
```

### 5b. Network Failure Tests

**Scenarios:**
- [ ] Network drops during call setup
- [ ] Network drops during active call
- [ ] Backend API timeout
- [ ] LiveKit connection lost
- [ ] Token expired during call
- [ ] Slow network conditions

**Test Script:**
```
1. Enable Developer Settings → Network Link Conditioner
2. Set profile: "100% Loss" or "3G"
3. Attempt to start call
4. Verify: Error message shown
5. Verify: App doesn't crash
6. Verify: User can retry
```

### 5c. CarPlay/Phone Handoff Tests

**Scenarios:**
- [ ] Start call on phone, plug into CarPlay
- [ ] Start call on CarPlay, unplug
- [ ] Switch audio between phone and CarPlay
- [ ] Background app, return from CarPlay
- [ ] App terminated, restart from CarPlay

**Test Script:**
```
1. Start call on phone
2. Plug into CarPlay mid-call
3. Verify: Audio switches to car speakers
4. Verify: UI appears in CarPlay
5. Unplug from CarPlay
6. Verify: Audio returns to phone
7. Verify: Call continues uninterrupted
```

### 5d. Data Management Tests

**Scenarios:**
- [ ] Logging enabled → sessions saved
- [ ] Logging disabled → sessions not saved
- [ ] Delete single session
- [ ] Delete all sessions
- [ ] View session details
- [ ] Session list pagination
- [ ] Offline session viewing

### 5e. Authentication Tests

**Scenarios:**
- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Token refresh on expiry
- [ ] Token storage in Keychain
- [ ] Logout and data clearing
- [ ] App restart preserves token

### 5f. Edge Cases

**Scenarios:**
- [ ] App launch with no internet
- [ ] Backend returns 500 error
- [ ] Invalid LiveKit token
- [ ] Microphone permission denied
- [ ] Multiple rapid taps on call button
- [ ] App in background for extended time
- [ ] Device low on memory
- [ ] iOS version compatibility (17.2+)

### 5g. Performance Tests

**Metrics to Track:**
- [ ] Call setup time (target: <2 seconds)
- [ ] API response times (target: <500ms)
- [ ] Audio latency (target: <200ms)
- [ ] Battery drain during call
- [ ] Memory usage
- [ ] CPU usage

### Test Environment Setup

**Required:**
- iOS 17.2+ device or simulator
- CarPlay simulator or vehicle
- Network Link Conditioner enabled
- Backend API configured
- LiveKit server running
- Test accounts created

**Tools:**
- Xcode Instruments (for performance)
- Network Link Conditioner (for network simulation)
- Console.app (for log analysis)
- Charles Proxy (for API debugging)

---

## Summary - Estimated Timeline

| Task | Time | Blocker? | Can Automate? |
|------|------|----------|---------------|
| **1. Build & Test** | 10 min | No | ❌ Requires Xcode |
| **2. Backend Wiring** | 30 min | Yes | ⚠️ Partially |
| **3. LiveKit Verification** | 1 hour | Yes | ❌ Requires hardware |
| **4. CarPlay Entitlement** | 2-3 weeks wait | Yes | ❌ Apple approval |
| **5. QA Testing** | 4 hours | No | ⚠️ Some automated |

**Total Active Work**: ~6 hours
**Total Calendar Time**: 2-3 weeks (waiting for Apple)

---

## Current Status ✅

**Completed:**
- ✅ All 19 source files in build target
- ✅ All 7 test files in build target
- ✅ LiveKit package dependency configured
- ✅ Configuration system implemented
- ✅ Backend API client ready
- ✅ Authentication framework ready
- ✅ Mock infrastructure for testing
- ✅ Project structure organized

**Ready to Execute:**
- 🔵 Build verification (10 min)
- 🔵 Test execution (5 min)
- 🟡 Backend configuration (30 min - requires backend URL)
- 🟡 LiveKit testing (1 hour - requires LiveKit server)
- 🔴 CarPlay testing (2-3 weeks - requires Apple approval)
- 🟡 QA testing (4 hours - requires above complete)

---

## Next Immediate Actions

**Right Now (You Can Do):**
1. Open CarPlaySwiftUI.xcodeproj in Xcode
2. ⌘⇧K → ⌘B → ⌘U to verify build and tests
3. Resolve any build issues
4. Confirm all 7 test files execute

**Next (Requires Backend):**
1. Set API_BASE_URL environment variable
2. Test authentication endpoints with curl
3. Run app and verify API integration
4. Check Console logs for request/response

**After That (Requires LiveKit):**
1. Configure LiveKit server
2. Update backend to return LiveKit credentials
3. Test audio streaming end-to-end
4. Verify microphone publish/subscribe

**Finally (Requires Apple):**
1. Request CarPlay entitlement
2. Wait for approval
3. Test on CarPlay simulator
4. Test on physical device

---

## Success Criteria

The project is production-ready when:
- ✅ All builds complete without errors
- ✅ All tests pass (16+ test cases)
- ✅ Backend API integrated and working
- ✅ LiveKit audio streaming functional
- ✅ CarPlay entitlement approved
- ✅ QA testing complete
- ✅ No critical bugs identified

---

**The foundation is complete. Time to execute the integration steps! 🚀**
