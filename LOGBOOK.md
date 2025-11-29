# Logbook

## 2025-11-27: Fix Railway duplicate config conflict

**Issue**: Railway build failing with `cd backend: No such file or directory`

**Root Cause**: Railway found two config files - `railway.json` AND `railway-node.json`. It used `railway.json` which pointed to root `nixpacks.toml` containing `cd backend && npm ci` commands. But since Railway dashboard has `Root Directory = backend`, we're already IN the backend directory - there's no nested backend folder.

**Solution**: Deleted the conflicting root configs:
- `railway.json` - was pointing to wrong nixpacks.toml
- `nixpacks.toml` - had `cd backend` commands (designed for root deployment)

Now only `railway-node.json` → `backend/nixpacks.toml` remains, which has correct commands without `cd backend` prefix.

**Files Removed**:
- `railway.json`
- `nixpacks.toml`

**Commit**: 84a67af

---

## 2025-11-27: Fix iPad CallKit crash

**Issue**: App Store review reported "error message after clicking on Start Call" on iPad Air (5th generation) with iPadOS 26.1.

**Root Cause**: CallKit is not supported on iPad. The app was using `CXCallController.request()` to start calls, which fails on iPad because iPads don't have phone functionality.

**Solution**: Modified `CallManager.swift` to detect the device type and bypass CallKit entirely on iPad:
- Added `isCallKitSupported` property that checks `UIDevice.current.userInterfaceIdiom == .phone`
- On iPad: Skip CallKit, directly configure audio session and notify delegate
- On iPhone: Continue using CallKit as before
- Updated `startAssistantCall()`, `endCurrentCall()`, and `reportCallConnected()` to handle optional CallKit

**Files Changed**:
- `Services/CallManager.swift`

**Branch**: `fix-ipad-callkit-bypass`

**Build Status**: Verified build succeeds for iPad simulator

---

## 2025-11-29: Fix App Store Rejection (5.1.1 + 2.1)

**Issue**: App Store rejected with 3 issues:
1. Guideline 5.1.1: Login gate - users must sign in before accessing AI voice chat
2. Guideline 5.1.1: IAP registration - users must register before purchasing
3. Guideline 2.1: Start Call error on iPhone 17 Pro Max / iOS 26.1

### Fix 1: Start Call Error (Issue 3)

**Root Cause**: Audio session configuration could fail on some devices, and CallKit requests had no timeout protection.

**Solution**:
- Added `CallManagerError` enum with `.timeout` and `.audioSessionFailed` cases
- Made speaker override non-fatal (call continues through earpiece if speaker fails)
- Added 10-second timeout protection for CallKit requests

**Files Changed**: `Services/CallManager.swift`

### Fix 2: Guest Mode (Issues 1 & 2)

**Root Cause**: `ContentView.swift` enforces login before app access. Users can't try the app or see paywall without signing in first.

**Solution**: Added "Continue as Guest" option:
- `Models/UserSettings.swift`: Added `isGuest` property
- `Screens/SignInScreen.swift`: Added "Continue as Guest" button
- `Services/AuthService.swift`: Modified `isAuthenticated` to accept device-only tokens for guests
- `Screens/SettingsScreen.swift`: Shows "Sign in with Apple" for guests instead of "Sign Out"
- `Services/HybridSessionLogger.swift`: Updated sync status message for guests

**Guest Limitations**:
- Sessions stored locally only (no cloud sync)
- Limited to free tier (15 min/month, free models only)
- Can sign in anytime from Settings to enable sync

**Backend**: Already supports device-only tokens. No changes needed.

**Build Status**: Verified iOS build succeeds

### Fix 3: Ensure Guest Mode is Truly Local-Only

**Issue**: Guest mode claimed "sessions stored locally" but CloudKit was still being used in multiple places.

**Solution**: Guard all CloudKit operations with `!settings.isGuest`:
- `HybridSessionLogger.swift`: Skip CloudKit in startSession, endSession, loadSessions, fetchSession, deleteSession, deleteAllSessions
- `AssistantCallCoordinator.swift`: Skip CloudKit sync in handleCallConnected and endAssistantCall
- `SettingsScreen.swift`: Hide "Restore from iCloud" button for guests, show appropriate footer text
- `SessionDetailScreen.swift`: Skip syncSummaryToCloudKit for guests

**Commits**:
- `768f38b`: Fix guest mode to truly skip CloudKit (local-only)
- Follow-up: SessionDetailScreen CloudKit guard
