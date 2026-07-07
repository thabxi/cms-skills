# Security Controls

An admin panel is a privileged write path into a production site. Every applicable control below ships with the build (Iron Rule 4) — written alongside each endpoint, form, and upload as it's created, not in a review pass afterward. Phase 9 runs the probes at the bottom.

## Authentication & sessions

- Use the app's existing auth or a proven library (Auth.js, Lucia, Supabase Auth, Clerk). **Never hand-roll password hashing or session tokens.**
- Passwords hashed with argon2id or bcrypt; never logged or echoed. If the build generates an initial admin credential, write it to a gitignored local file or the platform's env store and tell the user where — never into the repo or the report.
- Session cookies: `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict` for a subdomain admin), sensible expiry, rotated on login.
- Rate-limit login attempts with backoff. Offer 2FA only if the interview asked for it.

## Authorization

- **Deny by default.** Every admin page load and every mutation endpoint verifies the session **and** the `editor`/`admin` role **server-side**. Client-side route guards are UX, not security.
- Object-level checks: editors can only touch `cms_` tables; nothing in the CMS API can read or write app tables.
- Supabase: enable RLS on all `cms_` tables with role-based policies; the service-role key exists only in server env — grep the client build output to prove it.
- Draft content is never served to anonymous visitors. Preview uses a signed, expiring token or framework draft mode — not a query param like `?preview=true`.

## Input validation & injection

- One shared validation schema (Zod or equivalent) enforced on the server for every write — same rules the field editors show, so the API can't bypass alt-text, length, or type requirements.
- Database access only through the ORM/query builder with parameterized queries. No string-concatenated SQL anywhere, including search and ordering (`ORDER BY` columns from an allowlist, never from input).
- Rich text stored as structured JSON. If HTML is ever accepted or rendered, sanitize server-side with a strict allowlist (`sanitize-html` / DOMPurify-on-server) — on save **and** treat render output as untrusted.
- Slugs and any path-like fields: allowlist pattern (`^[a-z0-9]+(?:-[a-z0-9]+)*$`), rejecting `..`, slashes, and unicode tricks.
- Redirect targets (`cms_redirects.to_path`): relative paths or same-origin URLs only — an open redirect is an SEO and phishing hole.

## File uploads

- Validate type by **magic bytes**, not extension or client MIME; allowlist (`jpeg`, `png`, `webp`, `avif`, `gif`, `pdf` if asked). Enforce size limits server-side.
- **SVG is executable content** — reject it, or sanitize with an SVG-specific sanitizer and serve with `Content-Type: image/svg+xml` + `Content-Security-Policy: script-src 'none'`.
- Store under randomized names in object storage (bucket) or outside the webroot; never use a client-supplied filename as a path. Serve with `X-Content-Type-Options: nosniff`.
- Re-encode images on upload (resize/compress pipeline) — re-encoding also strips embedded payloads and EXIF location data.
- Upload endpoints get the same auth checks and their own rate limit.

## Web-layer protections

- CSRF: `SameSite` cookies **plus** an Origin/Referer check (or CSRF tokens) on every state-changing route — required because the admin is cookie-authenticated.
- Headers on admin responses: restrictive `Content-Security-Policy`, `frame-ancestors 'none'`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`.
- Errors: generic messages to the client (no stack traces, no SQL, no "user exists" vs "wrong password" distinction); full detail to server logs only.
- Secrets only in server-side env. Client bundle must contain no `SERVICE_ROLE`, `DATABASE_URL`, or API secrets — verified by grep in Phase 9.

## Operational

- **Audit log:** `cms_audit` table — who, what entity, action, timestamp, before/after snapshot for content changes. Written by the API layer on every mutation.
- Dependencies pinned via lockfile; `npm audit` (or equivalent) clean of high/critical at handoff.
- Migrations reversible; destructive migrations never run automatically. Note the database backup story (platform snapshots or `pg_dump` cron) in the Final Report if none exists.
- If the platform supports it (per architecture.md), an extra access layer in front of admin: IP allowlist, Cloudflare Access, or platform password protection.

## Verification probes (Phase 9) {#verification}

Run these and record results in the Final Report:

```bash
# Unauthenticated mutation → 401/403, not 200
curl -s -o /dev/null -w "%{http_code}" -X POST https://site.tld/api/cms/pages -d '{}'

# Admin page as anonymous → redirect to login (302/307/401)
curl -s -o /dev/null -w "%{http_code}" https://site.tld/admin

# Security headers present on admin
curl -sI https://site.tld/admin | grep -iE "content-security-policy|x-content-type-options|frame"

# No server secrets in the shipped client bundle
grep -rE "SERVICE_ROLE|DATABASE_URL|SUPABASE_SERVICE" .next/static/ dist/ 2>/dev/null && echo LEAK || echo clean
```

And by hand or with a test:
- Upload an `.html`/`.svg` file renamed to `.png` → rejected (magic-byte check).
- Save `<script>alert(1)</script><img src=x onerror=alert(1)>` in a rich text field → renders inert on the public page.
- Log in as a non-editor user (if roles exist) → admin routes and mutations return 403.
- Draft entry URL as anonymous visitor → not accessible without a valid preview token.
