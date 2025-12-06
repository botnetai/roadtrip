# Data Model: Email & Password Authentication

**Feature**: 001-email-password-auth
**Date**: 2025-12-06

## Entity Relationship Diagram

```
┌─────────────────────┐
│       users         │
├─────────────────────┤
│ id (PK)             │
│ email (UNIQUE)      │
│ password_hash       │
│ created_at          │
│ updated_at          │
│ email_verified      │
│ last_login_at       │
└─────────────────────┘
          │
          │ 1:N
          ▼
┌─────────────────────────────┐
│   password_reset_tokens     │
├─────────────────────────────┤
│ id (PK)                     │
│ user_id (FK → users.id)     │
│ token_hash                  │
│ expires_at                  │
│ used_at                     │
│ created_at                  │
└─────────────────────────────┘

┌─────────────────────┐
│  login_attempts     │
├─────────────────────┤
│ id (PK)             │
│ email               │
│ ip_address          │
│ attempted_at        │
│ success             │
└─────────────────────┘
```

## Table Definitions

### users

Stores email/password user accounts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | UUID v4 |
| email | TEXT | UNIQUE, NOT NULL | User's email (lowercase, trimmed) |
| password_hash | TEXT | NOT NULL | bcrypt hash (cost 12) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Account creation time |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last profile update |
| email_verified | BOOLEAN | NOT NULL, DEFAULT FALSE | Email verification status |
| last_login_at | TIMESTAMPTZ | NULL | Last successful login |

**Indexes**:
- `idx_users_email` on `email` (covered by UNIQUE constraint)

**Validation Rules**:
- Email must be valid format (RFC 5322)
- Email stored lowercase, trimmed
- Password hash never exposed in API responses

### password_reset_tokens

Stores password reset tokens for recovery flow.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | UUID v4 |
| user_id | TEXT | FK → users.id, NOT NULL | User requesting reset |
| token_hash | TEXT | NOT NULL | SHA-256 hash of token |
| expires_at | TIMESTAMPTZ | NOT NULL | Token expiration (created_at + 1 hour) |
| used_at | TIMESTAMPTZ | NULL | When token was used (NULL if unused) |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Token creation time |

**Indexes**:
- `idx_password_reset_tokens_user_id` on `user_id`
- `idx_password_reset_tokens_expires` on `expires_at`

**Validation Rules**:
- Token valid only if: `used_at IS NULL AND expires_at > NOW()`
- Only one active token per user (invalidate previous on new request)

### login_attempts (optional - for rate limiting audit)

Tracks login attempts for rate limiting and security monitoring.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | TEXT | PRIMARY KEY | UUID v4 |
| email | TEXT | NOT NULL | Attempted email (may not exist) |
| ip_address | TEXT | NOT NULL | Client IP address |
| attempted_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Attempt timestamp |
| success | BOOLEAN | NOT NULL | Whether login succeeded |

**Indexes**:
- `idx_login_attempts_email_time` on `(email, attempted_at)`
- `idx_login_attempts_ip_time` on `(ip_address, attempted_at)`

**Note**: This table is optional. Rate limiting can be done in-memory for MVP. Add this table later for audit trail and distributed rate limiting.

## PostgreSQL Migration

```sql
-- Migration: 001_add_email_auth_tables.sql

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  last_login_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_id
  ON password_reset_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires
  ON password_reset_tokens(expires_at);

-- Optional: Login attempts for audit trail
CREATE TABLE IF NOT EXISTS login_attempts (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  ip_address TEXT NOT NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  success BOOLEAN NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_email_time
  ON login_attempts(email, attempted_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_time
  ON login_attempts(ip_address, attempted_at);
```

## SQLite Equivalent (Local Dev)

```sql
-- SQLite version for local development

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  email_verified INTEGER NOT NULL DEFAULT 0,
  last_login_at TEXT
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  used_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## State Transitions

### User Account States

```
[Not Exists] → Register → [Active, Unverified]
                              │
                              ├─ Verify Email → [Active, Verified]
                              │
                              └─ (Can still use app)

[Active] → Delete Account → [Deleted]
```

### Password Reset Token States

```
[Created] → Used → [Consumed]
    │
    └─ Expired → [Invalid]
```

## Relationship to Existing Tables

The `users` table is **independent** of existing tables:

- `sessions.user_id`: Currently stores derived user IDs from device tokens or Apple IDs. Email users will have their `users.id` stored here.
- `user_subscriptions.user_id`: Same pattern - will store `users.id` for email users.
- No changes to existing Apple Sign In flow - those users don't have records in `users` table.

**Migration path for existing users**: None required. Email auth users are a new category. Future feature could allow linking Apple ID to email account.
