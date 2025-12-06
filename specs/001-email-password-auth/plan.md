# Implementation Plan: Email & Password Authentication

**Branch**: `001-email-password-auth` | **Date**: 2025-12-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-email-password-auth/spec.md`

## Summary

Add email + password authentication as an alternative to Sign in with Apple. Users can register, login, and reset passwords via email. The feature extends existing AuthService (iOS) and backend auth endpoints while maintaining current Sign in with Apple functionality.

## Technical Context

**Language/Version**: Swift 5.9 (iOS), Node.js 20+ (backend)
**Primary Dependencies**: SwiftUI, AuthenticationServices, Express, pg, bcrypt, nodemailer
**Storage**: PostgreSQL on Railway (production), SQLite (local dev)
**Testing**: XCTest (iOS), manual testing (backend - solo dev pragmatism)
**Target Platform**: iOS 17.2+, Node.js server on Railway
**Project Type**: Mobile + API
**Performance Goals**: Login/registration < 2s, password reset email < 5min delivery
**Constraints**: Must not break existing Sign in with Apple flow
**Scale/Scope**: Solo dev project, ~5-10 screens affected

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. UX Clarity & Delight | PASS | Clear error messages specified in FR-002, FR-003, FR-006; feedback within 100ms for auth actions |
| II. Visual Polish & Beauty | PASS | Will follow existing Settings screen patterns; both auth options presented cleanly |
| III. Modular Architecture | PASS | Extends existing AuthService; no new circular dependencies |
| IV. Simplicity First | PASS | Uses existing patterns (PostgreSQL, Express routes); minimal new dependencies (bcrypt, nodemailer) |
| V. Maintainability by Design | PASS | Self-documenting function names; follows existing codebase conventions |

**Gate Status**: PASSED - No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-email-password-auth/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── auth-api.yaml    # OpenAPI spec for auth endpoints
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
# Mobile + API structure (existing)
backend/
├── server.js            # Add new auth routes
├── database.js          # Add users, password_reset_tokens tables
├── middleware/
│   └── auth.js          # Update to validate email/password sessions
└── services/
    └── email.js         # NEW: Email service for password reset

# iOS App (existing structure)
Services/
├── AuthService.swift    # Extend with email/password methods
└── Configuration.swift  # Add new auth endpoint URLs

Screens/
├── SettingsScreen.swift # Add email sign-in option
└── EmailAuthScreen.swift # NEW: Email login/register/reset UI
```

**Structure Decision**: Extends existing Mobile + API structure. No new modules - adds to existing Services/ and Screens/ directories on iOS, and backend/ directory on server.

## Complexity Tracking

> No constitution violations - this section is empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | - | - |
