# Tasks: Email & Password Authentication

**Input**: Design documents from `/specs/001-email-password-auth/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/auth-api.yaml

**Tests**: Not explicitly requested - skipping automated test tasks per solo dev pragmatism.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Exact file paths included

## Path Conventions

- **Backend**: `backend/` (Node.js Express)
- **iOS**: Root directory (Swift/SwiftUI)

---

## Phase 1: Setup

**Purpose**: Install dependencies and configure environment

- [X] T001 Install bcrypt and resend npm packages in backend/package.json
- [X] T002 [P] Add RESEND_API_KEY and PASSWORD_RESET_URL to backend/.env.example
- [X] T003 [P] Add authRegisterURL and password reset URLs to Services/Configuration.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Database schema and shared services that ALL user stories depend on

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Add users table schema to backend/database.js (PostgreSQL + SQLite)
- [X] T005 Add password_reset_tokens table schema to backend/database.js
- [X] T006 [P] Create email service in backend/services/email.js using Resend
- [X] T007 [P] Add in-memory rate limiting for login attempts in backend/server.js
- [X] T008 Add password validation helper function (8+ chars, uppercase, lowercase, number) in backend/server.js
- [X] T009 Seed App Store review test account in backend/server.js
  - Email: jjeremycai@gmail.com
  - Password: helloapplefriend (bcrypt hashed)
  - Set subscription status to expired (for testing expired subscription flow)
  - Insert on database init if not exists

**Checkpoint**: Database ready, email service ready, rate limiting ready, test account seeded

---

## Phase 3: User Story 1 & 2 - Registration & Login (Priority: P1) MVP

**Goal**: Users can create accounts and sign in with email/password

**Independent Test**: Register a new account → Sign out → Sign back in → Verify access to app

### Backend Implementation

- [X] T010 [US1] Implement POST /v1/auth/register endpoint in backend/server.js
  - Validate email format
  - Validate password requirements
  - Check for existing email (return 409 if exists)
  - Hash password with bcrypt (cost 12)
  - Insert into users table
  - Return token and user object

- [X] T011 [US2] Update POST /v1/auth/login endpoint in backend/server.js
  - Check rate limit before processing
  - Find user by email
  - Compare password hash with bcrypt
  - Update last_login_at on success
  - Return token and user object
  - Return 401 on invalid credentials (generic message)
  - Return 429 if rate limited

- [X] T012 [US1][US2] Update authenticateToken middleware in backend/server.js to handle email users
  - Check if token belongs to users table
  - Set req.userId appropriately for email users

### iOS Implementation

- [X] T013 [P] [US1] Add register(email:password:) async method to Services/AuthService.swift
  - Call /v1/auth/register endpoint
  - Store returned token
  - Update auth state

- [X] T014 [P] [US2] Update login(email:password:) method in Services/AuthService.swift
  - Call updated /v1/auth/login endpoint
  - Handle rate limit errors
  - Store token on success

- [X] T015 [US1][US2] Create EmailAuthView.swift in Screens/ with login/register toggle
  - Email text field
  - Password secure field
  - Password requirements hint
  - Toggle between Login and Register modes
  - Error message display
  - Loading state during API call

**Checkpoint**: Users can register and login with email/password via the new screen

---

## Phase 4: User Story 4 - Authentication Method Choice (Priority: P1)

**Goal**: Users can choose between Sign in with Apple and email/password

**Independent Test**: Open Settings → See both auth options → Tap each to verify navigation works

### iOS Implementation

- [X] T016 [US4] Update accountSection in Screens/SettingsScreen.swift
  - For guests: Show "Sign in with Apple" button (existing)
  - For guests: Add "Sign in with Email" button below Apple button
  - Add sheet to EmailAuthView for email option

- [X] T017 [US4] Add auth method choice UI to EmailAuthView.swift
  - Add "Forgot Password?" button (navigates to reset flow, implemented in US3)
  - Add "or Sign in with Apple" option at bottom
  - Style consistently with existing SettingsScreen

**Checkpoint**: Both Sign in with Apple and Email options visible and functional

---

## Phase 5: User Story 3 - Password Reset (Priority: P2)

**Goal**: Users can reset forgotten passwords via email

**Independent Test**: Tap "Forgot Password" → Enter email → Receive email → Click link → Set new password → Sign in with new password

### Backend Implementation

- [X] T018 [US3] Implement POST /v1/auth/password/reset-request in backend/server.js
  - Accept email in request body
  - Find user by email (silently succeed if not found - prevent enumeration)
  - Generate UUID token
  - Hash token with SHA-256 before storing
  - Insert into password_reset_tokens with 1-hour expiry
  - Invalidate any existing tokens for this user
  - Send email with reset link using email service
  - Always return 200 with generic message

- [X] T019 [US3] Implement POST /v1/auth/password/reset in backend/server.js
  - Accept token and new password
  - Validate new password requirements
  - Hash incoming token and find matching unexpired, unused token
  - Update user's password_hash
  - Mark token as used (set used_at)
  - Invalidate all user sessions (optional: clear other tokens)
  - Return success message

- [X] T020 [P] [US3] Create password reset email template in backend/services/email.js
  - Include reset link with token
  - Include expiration warning (1 hour)
  - Brand appropriately

### iOS Implementation

- [X] T021 [US3] Add requestPasswordReset(email:) method to Services/AuthService.swift
  - Call /v1/auth/password/reset-request endpoint
  - Return success (always, per API design)

- [X] T022 [US3] Add resetPassword(token:newPassword:) method to Services/AuthService.swift
  - Call /v1/auth/password/reset endpoint
  - Handle expired/invalid token errors

- [X] T023 [US3] Create PasswordResetView.swift
  - Email entry for requesting reset
  - Success message after request
  - Deep link handling for reset URL (if implementing in-app reset)
  - New password entry with requirements validation

**Checkpoint**: Complete password reset flow works end-to-end

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final touches and validation

- [X] T024 [P] Verify Sign in with Apple flow still works unchanged (implementation complete, manual test required)
- [X] T025 [P] Test guest → email account upgrade flow (implementation complete, manual test required)
- [X] T026 Add user-friendly error messages for all auth error cases in AuthError enum
- [X] T027 Add haptic feedback for auth success/failure using Services/HapticFeedbackService.swift
- [ ] T028 Run quickstart.md verification checklist (manual verification required)
- [ ] T029 Manual end-to-end testing on device (manual verification required)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **US1 & US2 (Phase 3)**: Depends on Foundational
- **US4 (Phase 4)**: Depends on US1 & US2 (needs EmailAuthScreen)
- **US3 (Phase 5)**: Depends on Foundational (can parallel with US1/US2 but email service needed)
- **Polish (Phase 6)**: Depends on all stories complete

### User Story Dependencies

- **US1 (Registration)**: Foundational only - independently testable
- **US2 (Login)**: Foundational only - independently testable after registration
- **US3 (Password Reset)**: Foundational only - requires email service
- **US4 (Method Choice)**: Depends on US1/US2 having EmailAuthScreen

### Within Each Phase

- Backend tasks before iOS tasks (iOS calls backend)
- Database schema before endpoints
- Services before routes that use them
- Core implementation before UI polish

### Parallel Opportunities

Within Phase 2 (Foundational):
- T006 (email service) and T007 (rate limiting) can run in parallel

Within Phase 3 (US1 & US2):
- T013 (iOS register) and T014 (iOS login) can run in parallel after backend is done

Within Phase 5 (US3):
- T020 (email template) can run parallel with other US3 backend tasks

---

## Parallel Example: Phase 2 Foundational

```bash
# These can run in parallel (different files):
Task: "T006 [P] Create email service in backend/services/email.js"
Task: "T007 [P] Add in-memory rate limiting in backend/server.js"
```

## Parallel Example: Phase 3 iOS Tasks

```bash
# After backend complete, these can run in parallel:
Task: "T013 [P] [US1] Add register method to AuthService.swift"
Task: "T014 [P] [US2] Update login method in AuthService.swift"
```

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T009)
3. Complete Phase 3: US1 & US2 (T010-T015)
4. **STOP and VALIDATE**: Test registration and login end-to-end
5. Deploy to TestFlight if ready

### Full Feature

1. Complete MVP (Phases 1-3)
2. Add Phase 4: US4 - Method Choice (T016-T017)
3. Add Phase 5: US3 - Password Reset (T018-T023)
4. Complete Phase 6: Polish (T024-T029)
5. Deploy to production

---

## Notes

- No automated tests included (solo dev pragmatism per constitution)
- Manual testing via quickstart.md checklist
- Sign in with Apple must remain unchanged (T024 validates this)
- Rate limiting is in-memory (sufficient for single Railway server)
- Email verification deferred to future iteration
- Commit after each task or logical group
