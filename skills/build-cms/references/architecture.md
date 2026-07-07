# Architecture Proposal (Phase 3 — checkpoint 2)

After the interview, present the user with 2–3 concrete options for **where the CMS lives and how it's accessed**, derived from discovery facts. One question, one pick, then build with no further input. Always mark one option **Recommended** and say why in one sentence tied to their stack.

## The three option shapes

### Option A — Embedded admin (default recommendation)
Admin lives inside the app as a route group: Next.js `app/(admin)/admin`, Nuxt/SvelteKit/Astro-SSR equivalent.

- **Access:** `https://site.tld/admin`, protected by auth middleware on the whole group.
- **Pros:** one deploy, shares the app's UI stack and design tokens, same database connection, preview is trivial (same runtime renders drafts).
- **Cons:** admin code ships in the same project (excluded from public bundles via route grouping); admin shares the app's blast radius.
- **Recommend when:** the app has (or will have, per the interview's rendering decision) a server runtime, and editors are the owner or a small team.

### Option B — Separate admin app
Admin is its own app (`apps/admin` in a monorepo, or a sibling repo), deployed independently, talking to the same database server-side or through an authenticated API.

- **Access:** `https://admin.site.tld` (subdomain keeps cookies and CSP fully separate).
- **Pros:** hard security boundary; public site can stay a pure static build/SPA; admin can use a different framework; admin outages can't touch the site.
- **Cons:** second deploy + env config; live preview needs a preview endpoint or shared rendering package.
- **Recommend when:** the public app is a client-only SPA staying static, editors are external to the dev team, or the interview surfaced strict isolation/compliance needs.

### Option C — Embedded open-source headless CMS
Adopt a mature self-hosted CMS instead of a bespoke admin: Payload (native inside Next.js), or Directus/Strapi as a separate service (making this a variant of B).

- **Access:** the package's admin route (e.g. `/admin`), themed to the brand.
- **Pros:** production-grade editor UI, auth, media library, and access control on day one; less code to maintain.
- **Cons:** dependency weight and upgrade obligations; less Webflow-custom; the content model must fit its conventions.
- **Recommend when:** the user values speed and maturity over a tailored editor, and the stack matches (Payload → Next.js).
- **Still required:** `FIELD-MAP.md`, front-end wiring, and the full SEO layer — adopting a CMS package satisfies Phase 5 only.

## Access hardening add-ons (state as defaults, don't ask separately)

Include in the proposal as one line per option rather than extra questions:

- Default: role-checked auth at `/admin` or the subdomain (per security.md).
- If the interview said editors are internal-only, add one platform layer on top: IP allowlist, Cloudflare Access / Vercel protection, or VPN-only — pick what the detected host supports and note it as part of the option.
- Admin is always `noindex`, excluded from the sitemap, and disallowed in robots.txt regardless of option.

## Per-stack menu

| Discovery result | Offer | Recommend |
|---|---|---|
| Next.js (App Router) | A, B, C (Payload) | A — unless editors are external, then B |
| Nuxt / SvelteKit / Remix | A, B | A |
| Astro (SSG or hybrid) | A (switch to hybrid rendering), B | A if hybrid is acceptable; B for strict static |
| Vite/CRA client-only SPA | B, plus the rendering plan chosen in the interview | B |
| Plain static HTML | B + publish-triggered static regeneration | B |
| Supabase already in stack | A with RLS on `cms_` tables, B | A |

## After the pick

Load the matching playbook from [stacks/](stacks/) — `nextjs-supabase.md`, `astro.md`, `sveltekit.md`, or `vite-spa.md`. It prescribes the concrete file map, auth wiring, publishing pipeline, SEO endpoints, and stack-specific gotchas for Phases 4–7. No playbook for the stack? Build from the generic references and note it in the Final Report.

## How to present it

One message: recap 3–5 discovery facts ("Next.js 15 App Router, Supabase Postgres, deployed on Vercel, existing Supabase auth"), then the applicable options with 2–3 trade-off bullets each and the recommendation flagged. After the user picks, confirm in a single line — "Building Option A: `/admin` inside the app, reusing Supabase auth with an `editor` role, media in Supabase Storage" — and start Phase 4. That confirmation line is the last thing said to the user before the Final Report.
