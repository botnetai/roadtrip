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
