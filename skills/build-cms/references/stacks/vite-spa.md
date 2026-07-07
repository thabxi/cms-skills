# Playbook: Vite/CRA Client-Only SPA (incl. Lovable-style Vite + React + Supabase)

The hard case: **no server runtime**, so nothing here is crawlable and there is nowhere to hang an admin. The interview's rendering decision (discovery.md) drives everything — settle it before checkpoint 2.

## Rendering plan (the interview's three options, concretely)

| Plan | What it means here | SEO result |
|---|---|---|
| **(a) Migrate to a framework** | Vite React → React Router v7 framework mode (smallest lift from an existing `react-router` app) or Next.js. Then follow that stack's playbook; this becomes Option A territory | Full |
| **(b) Prerender on publish** | Site stays a static build; a build step fetches published CMS content and bakes it in (`vite-plugin-ssr`/`vike` prerender, or a render script). Publishing triggers a rebuild via deploy hook | Full, with minutes of publish latency |
| **(c) Stay CSR** | Content fetched client-side at runtime | Weak — Google renders JS eventually; OG/Twitter scrapers and most other crawlers see nothing. Only acceptable for app-like products where the user says SEO doesn't matter |

Recommend (a) when SEO matters and the app is young; (b) when the user won't restructure; never silently pick (c).

## Architecture: always Option B (separate admin)

The public SPA has no server, so the admin is its own deployable:

```
apps/admin/          # small SSR app (Next.js or plain Vite SPA — admin needs no SEO)
  or: admin/ + api/  # Vite admin front end + Hono/Express API if no framework wanted
```

- With **Supabase already present** (Lovable default): the admin can be a second Vite SPA using Supabase Auth + RLS as the security boundary — there's no custom API to protect, RLS *is* the server-side check. Editor role in `app_metadata` or a `cms_editors` table; RLS policies: `anon` reads `status = 'published'` only, editors write.
- Without Supabase: the admin needs a real backend (Hono on Cloudflare/Vercel functions + Postgres/SQLite via Drizzle). Don't put mutations behind a static site's client code.

## Publishing pipeline (plan b)

1. Publish action flips `status` → calls the host's **deploy hook** (Netlify/Vercel/Cloudflare Pages build hook URL stored server-side).
2. The site's build fetches published content (script in `prebuild`) and writes it as JSON/props consumed at build time.
3. Sitemap, `robots.txt`, and redirect files are **generated in the same build**: `_redirects` (Netlify), `vercel.json` redirects, or `_headers` — slug-change 301s land here from `cms_redirects`.

## SEO wiring specifics

- Meta/OG tags must be **in the built HTML**, one file per route (prerender output) — `react-helmet` at runtime does not exist for scrapers under plan (b)-less CSR.
- Real 404s: configure the host so unknown paths return 404 status, with the SPA fallback only for known client routes — the default "serve index.html for everything" is a soft-200 farm that poisons indexing.
- JSON-LD goes into the prerendered HTML like any other head tag.

## Gotchas

- Lovable exports keep the Supabase **anon key in client code — that's fine by design**, but only if RLS is on; discovery must check `alter table … enable row level security` actually exists for every exposed table.
- `import.meta.env.VITE_*` vars are public. Anything secret (deploy hook URL, service key) must live only in the admin's server/env — grep the built `dist/` for leaks in Phase 9.
- Client-side routing hides broken links from `curl`-based verification — under plan (b), verify against the built `dist/` HTML files, not the dev server.
