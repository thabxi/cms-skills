# Playbook: Next.js (App Router) + Supabase

The most common vibe-coded stack (v0, Bolt, Lovable exports). Default architecture: **Option A**, embedded admin, RLS-backed.

## File map

```
app/(admin)/admin/            # admin UI (route group keeps it out of public layouts)
  layout.tsx                  # server-side session + role check, redirects to login
  [collection]/page.tsx       # list views
  [collection]/[id]/page.tsx  # editor
app/api/cms/preview/route.ts  # signed draft-preview entry (enables draftMode)
lib/cms/
  schema.ts                   # zod schemas per collection (client + server share)
  queries.ts                  # typed reads, published-only for public callers
  actions.ts                  # 'use server' mutations, validate → write → revalidate
supabase/migrations/NNN_cms.sql
scripts/seed-cms.ts           # Phase 6 seed content
middleware.ts                 # /admin guard + cms_redirects lookup
app/sitemap.ts  app/robots.ts
```

## Auth & authorization

- Reuse Supabase Auth. Editor role in **`app_metadata`** (set via service-role admin API) or a `cms_editors` table — never `user_metadata`, which users can edit themselves.
- `middleware.ts` blocks `/admin` without a session; the admin `layout.tsx` re-verifies session **and role** server-side (middleware alone is not sufficient — it can be bypassed by direct route handler calls).
- **RLS on every `cms_` table:** `SELECT` for `anon` only where `status = 'published'`; `ALL` for authenticated users who pass the editor check. Public pages read with the anon key through RLS; the service-role key appears only in server-only code (never in a file imported by a client component).
- Mutations are server actions in `lib/cms/actions.ts`: check role → parse with zod → write → `revalidateTag`.

## Rendering & publishing

- Content pages are **server components** using `generateMetadata` for the SEO fields — a `"use client"` page can't set metadata, so if a vibe-coded page is client-only, split it: server wrapper fetches CMS data + metadata, passes props to the client component.
- Tag reads with `unstable_cache`/`fetch` tags per entity (`cms:home`, `cms:posts`); publish action calls `revalidateTag` — instant updates with static-speed serving.
- Draft preview: `/api/cms/preview?token=…&path=…` verifies a short-lived signed token (HMAC of path + expiry with a server secret), calls `draftMode().enable()`, redirects. Queries branch on `draftMode().isEnabled` to include drafts.

## Media

- Supabase Storage bucket `cms-media`: public read, insert/delete restricted to editors via storage policies. Upload through a server action that does the magic-byte check and re-encode (`sharp`) before `storage.upload`.
- Add the Supabase host to `images.remotePatterns` in `next.config`; render everything through `next/image`.

## SEO wiring

- `app/sitemap.ts` and `app/robots.ts` query published entries at request time — nothing to regenerate.
- Redirects: middleware loads `cms_redirects` (cache it — a `Map` revalidated by tag or a 60s in-memory TTL; don't query per-request at the edge) and returns `NextResponse.redirect(dest, 301)` before route matching.
- JSON-LD: `<script type="application/ld+json">` emitted in the server component from CMS fields.

## Gotchas

- Supabase server client needs `cookies()` from `next/headers` — use the `@supabase/ssr` helpers; the old auth-helpers pattern breaks on newer Next.
- `revalidatePath('/')` doesn't touch dynamic route caches reliably — prefer tags.
- Vercel: server actions have a 1MB default body limit — route uploads through a dedicated route handler with `bodySizeLimit` raised, or upload client → Storage directly with a signed upload URL.
- Lovable/Bolt exports often already contain a Supabase client and tables — discovery must inventory them; RLS may be missing entirely on existing tables (note it in the report, don't silently fix app tables).
