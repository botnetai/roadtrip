# Research: Email & Password Authentication

**Feature**: 001-email-password-auth
**Date**: 2025-12-06

## Password Hashing

**Decision**: Use bcrypt with cost factor 12

**Rationale**:
- Industry standard for password hashing
- Built-in salt generation prevents rainbow table attacks
- Cost factor 12 balances security with performance (~250ms hash time)
- Already available as npm package `bcrypt`

**Alternatives Considered**:
- Argon2: More resistant to GPU attacks but overkill for this scale; bcrypt is sufficient
- scrypt: Good but less widely adopted; bcrypt has better ecosystem support
- SHA-256 with salt: Not suitable for passwords (too fast, enables brute force)

## Email Service Provider

**Decision**: Use Resend (or Railway's built-in SMTP if available)

**Rationale**:
- Simple API, generous free tier (100 emails/day)
- Good deliverability
- Easy integration with Node.js via `resend` npm package
- Can fall back to nodemailer + SMTP if needed

**Alternatives Considered**:
- SendGrid: More complex setup, overkill for low volume
- AWS SES: Requires AWS account setup, more operational overhead
- Mailgun: Good but more expensive for low volume
- nodemailer + SMTP: Viable fallback, but deliverability issues with self-hosted

## Rate Limiting Strategy

**Decision**: In-memory rate limiting with IP + email combination

**Rationale**:
- Spec requires 5 attempts per 15 minutes per email
- express-rate-limit package provides simple implementation
- Track by both IP and email to prevent distributed attacks
- In-memory is sufficient for single-server Railway deployment

**Alternatives Considered**:
- Redis-based: Overkill for single server; adds operational complexity
- Database-based: Adds latency to auth flow; not needed at this scale

## Password Reset Token Format

**Decision**: UUID v4 tokens, stored hashed in database

**Rationale**:
- UUIDs are cryptographically random and URL-safe
- Storing hashed tokens prevents exposure if database is compromised
- 1-hour expiration per spec requirement (FR-008)

**Alternatives Considered**:
- JWT tokens: More complex, harder to revoke, unnecessary for this use case
- Short numeric codes: Less secure, better for SMS (not applicable here)

## iOS Authentication Flow

**Decision**: Extend existing AuthService with email/password methods

**Rationale**:
- AuthService already handles token storage in Keychain
- Existing `login(email:password:)` method stub exists
- Maintains single source of truth for auth state

**Alternatives Considered**:
- New EmailAuthService: Unnecessary duplication; violates Principle III (Modular Architecture)
- Firebase Auth: External dependency, vendor lock-in, overkill for simple email/password

## Session Management

**Decision**: Reuse existing device token pattern with user linkage

**Rationale**:
- Current system uses device tokens stored in UserDefaults + Keychain
- Email users get same token format but linked to user record in database
- Enables seamless transition between guest → email account

**Alternatives Considered**:
- JWT-only sessions: Would require significant refactoring; device tokens work well
- Separate session table: Adds complexity; current pattern sufficient

## User Table Design

**Decision**: New `users` table with email as unique identifier

**Rationale**:
- Email is natural unique identifier for email/password auth
- Separate from Apple ID users (different auth mechanism)
- Password hash stored in same row for simplicity

**Alternatives Considered**:
- Unified users table with auth_type column: More complex joins; keep Apple users separate for now
- email_accounts table: Unnecessary indirection

## Email Verification

**Decision**: Defer email verification to future iteration

**Rationale**:
- Adds complexity to initial implementation
- Users can still use app without verified email
- Password reset flow implicitly verifies email ownership
- Can add later without breaking changes

**Alternatives Considered**:
- Require verification before login: Blocks user from app; poor UX
- Soft verification with reminder: Nice to have but scope creep
