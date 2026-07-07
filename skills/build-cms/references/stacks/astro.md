# Playbook: Astro

Astro sites are usually fully prerendered — the CMS decision is whether to go **hybrid** (admin SSR, public pages static) or keep strict SSG with rebuilds on publish.

## Recommended: hybrid (Option A)

Keep `output: 'static'` and opt the admin into SSR per-page (`export const prerender = false`) with an adapter (`@astrojs/vercel`, `@astrojs/node`, `@astrojs/cloudflare`).

```
src/pages/admin/[...all].astro   # prerender=false; or a dedicated admin/ subtree
src/actions/cms.ts               # Astro Actions: validated mutations (zod built in)
src/lib/cms/queries.ts           # Drizzle reads; published-only helper for public pages
src/middleware.ts                # /admin session guard + cms_redirects 301s
src/pages/sitemap.xml.ts         # custom endpoint (see below)
db/migrations/  scripts/seed-cms.ts
```

- **DB:** Drizzle + SQLite (single server/Fly) or Postgres/Supabase (serverless). Astro DB also works for small sites.
- **Auth:** no app auth exists in most Astro sites — better-auth or Lucia-style sessions; guard in `middleware.ts` **and** re-check the editor role inside every Action (middleware doesn't cover direct action calls).
- **Mutations:** Astro Actions give you zod validation and CSRF-safe POSTs out of the box; use them instead of hand-rolled API routes.

## Publishing

- Public pages prerendered at build → **publish triggers the host's deploy hook** (URL in server env). Content changes go live on rebuild (1–3 min).
- If the user needs instant publish, flip public content pages to `prerender = false` too (full SSR) and skip the hook — trade build-time speed for freshness.
- Draft preview: a `prerender = false` preview route that renders the same components with draft data behind a signed, expiring token — prerendered pages can't show drafts.

## SEO wiring

- Meta/OG/JSON-LD render in layout `<head>` from CMS props — Astro is server-first, so this is automatic; no islands needed for content.
- **Don't rely on `@astrojs/sitemap`** — it only sees routes known at build time from the file tree. Write `src/pages/sitemap.xml.ts` querying published entries (works both prerendered-per-build and SSR).
- Redirects: `cms_redirects` applied in `src/middleware.ts` (SSR/hybrid). For strict-static hosting, emit the host's redirect file (`_redirects`, `vercel.json`) during build instead.
- Images: local assets through `astro:assets`/`<Image>`; CMS-uploaded remote images need `image.domains` in `astro.config`.

## Gotchas

- `Astro.locals` typing: declare the session/user shape in `env.d.ts` or middleware data won't type-check.
- Actions run on the server but are callable from anywhere — the role check belongs **inside** each action, not only in middleware.
- Content collections (`src/content/`) are build-time and file-based — don't migrate CMS content *into* them; they're the thing being replaced. If the site already uses them (markdown blog), the migration path is content-collection entries → `cms_` tables as seed data.
- Cloudflare adapter: no Node `sharp` — use the built-in image service or re-encode uploads in the action with a WASM encoder.
