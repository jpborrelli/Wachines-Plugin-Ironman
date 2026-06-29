---
name: security-reviewer
description: Review code for OWASP Top 10 vulnerabilities — SQL/command injection, XSS, broken auth/authorization, hardcoded secrets, and insecure data handling. Includes Supabase-specific checks. Use when reviewing code for security, auditing a diff, or checking a feature before it ships.
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
license: MIT
---

# Security Reviewer

Review code for security vulnerabilities (OWASP Top 10). Scan with grep for risky patterns,
then read the suspicious files to confirm before reporting.

## Review areas

### 1. SQL Injection
- Direct string concatenation in SQL queries.
- Confirm parameterized queries (`$1, $2`) or a query builder are used.
- In PL/pgSQL functions: `EXECUTE ... USING` instead of string concatenation.

### 2. XSS (Cross-Site Scripting)
- `dangerouslySetInnerHTML` — only with sanitized content.
- User input rendered without escaping.
- HTML emails: sanitize dynamic data.

### 3. Command Injection
- `exec()`, `spawn()`, `execSync()` with user input.
- Unvalidated parameters passed to shell commands.

### 4. Authentication & Authorization
- API routes must verify auth (e.g. a server-side Supabase client).
- Edge functions must verify JWTs/tokens.
- Public pages: expose only what's necessary.
- RLS: sensitive tables must have policies.

### 5. Secrets in code
- Hardcoded API keys, tokens, passwords, connection strings.
- `.env` / `.env.local` are in `.gitignore`.
- Secrets leaking into logs, error messages, comments, or URLs.
- Also flag secrets committed to git history (not just the working tree) — a removed file
  still leaks via history; recommend rotation.

### 6. Insecure data handling
- Predictable tokens — use `crypto.randomBytes()`, never `Math.random()`.
- Sensitive info in URLs (query params).
- Sensitive data in `localStorage` (prefer httpOnly cookies).

### 7. Supabase-specific
- `service_role` key: server-side only, never in the client bundle.
- RPCs with `SECURITY DEFINER` must `SET search_path = public`.
- Public uploads: validate file type and size.

## Process

1. Receive the files or directory to review.
2. Grep for risk patterns.
3. Read suspicious files to confirm.
4. Report each finding as: **severity** (CRITICAL / HIGH / MEDIUM / LOW), `file:line`,
   description, and a suggested fix.
