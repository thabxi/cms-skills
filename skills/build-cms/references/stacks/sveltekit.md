# Playbook: SvelteKit

SvelteKit is server-first with form actions built in — the CMS fits naturally as **Option A**, an embedded route group.

## File map

```
src/routes/(admin)/admin/
  +layout.server.ts            # session + editor role check → redirect(303, '/login')
  [collection]/+page.server.ts # list load
  [collection]/[id]/+page.server.ts  # editor load + form actions (save/publish)
src/lib/server/cms/
  schema.ts                    # zod schemas (shared shapes importable client-side)
  queries.ts                   # Drizzle reads; publishedOnly() for public loads
src/hooks.server.ts            # session resolution + cms_redirects 301s
src/routes/sitemap.xml/+server.ts
src/routes/robots.txt/+server.ts
drizzle/migrations/  scripts/seed-cms.ts
```

- **DB:** Drizzle + Postgres (serverless hosts) or SQLite (node adapter on a VPS). Existing Supabase → use it, RLS optional since all access goes through `$lib/server`.
- **Auth:** existing Lucia/better-auth/Supabase session if present; otherwise better-auth. Resolve the session once in `hooks.server.ts` into `event.locals`, then the admin `+layout.server.ts` enforces the role. **Form actions and any `+server.ts` under `(admin)` must re-check `locals` role** — layout guards don't run for direct POSTs to actions.
- **Mutations:** form actions with zod parsing (`fail(400, …)` returns field errors to the editor UI cleanly). Use `use:enhance` for the Webflow-feel (no full page reloads).

## Rendering & publishing

- Public pages: server `load` reads published content; with `@sveltejs/adapter-vercel`/netlify use ISR config or plain SSR — either is crawler-visible.
- If pages are `prerender = true`, publish must hit a deploy hook (same pattern as Astro) — prefer SSR/ISR to keep publish instant.
- Draft preview: signed token endpoint sets an httpOnly preview cookie; `load` functions include drafts when the cookie verifies. Clear it on logout.
- Meta tags: page `load` returns the SEO fields; layout renders them in `<svelte:head>`. JSON-LD in the same block (use `{@html}` carefully — serialize with `JSON.stringify` and escape `<`).

## SEO wiring

- `sitemap.xml/+server.ts` and `robots.txt/+server.ts` query published entries per request — nothing to regenerate.
- Redirects in `hooks.server.ts` `handle`, before `resolve(event)`: look up `cms_redirects` (cached Map with TTL), `throw redirect(301, dest)`.
- Images: `@sveltejs/enhanced-img` for local; CMS uploads re-encoded server-side (`sharp`) and served from the bucket with explicit width/height in the field data (store dimensions in `cms_media` at upload).

## Gotchas

- Anything imported from `$lib/server/**` is build-enforced server-only — put queries and the DB client there so a client-component import fails the build instead of leaking.
- `+layout.server.ts` guards **do not** protect sibling `+server.ts` routes or form actions on direct request — every mutation re-checks `locals`.
- `event.locals` typing goes in `src/app.d.ts` (`App.Locals`) or nothing type-checks.
- Prerendered routes can't read cookies — a page using the preview cookie must not be `prerender = true`.
