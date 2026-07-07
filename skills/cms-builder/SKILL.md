---
name: cms-builder
description: Use when a vibe-coded or front-end-first app needs a content management system — hardcoded text/images must become editable, content needs managing in production without redeploys, the user asks for an admin panel or "CMS like Webflow", or the site must become SEO-ready with editable meta tags, sitemaps, and structured data.
---

# CMS Builder

## Overview

Retrofit a Webflow-like CMS onto an existing app. The app already has a front end (usually vibe-coded, content hardcoded in components); this skill adds a database-backed content layer, an admin UI for editors, and production-grade SEO — then rewires the front end so **every content field comes from the CMS**.

**Core principle: the front end is the spec.** You do not invent a content model — you extract it from the existing pages, confirm it with the user, and map every field. A CMS that covers 80% of the site's content is a failed CMS: editors will still need a developer.

## The Iron Rules

1. **Interview before you build.** Complete Phase 1 (discovery) and Phase 2 (interview) before writing any schema or admin code. Do not scaffold "a reasonable CMS" and adjust later — the interview answers change the architecture (auth, database, rendering, publishing).
2. **No unmapped fields.** Produce `FIELD-MAP.md` before building. Every user-visible string, image, link, and list on every page appears in it. The build is done only when every row is `wired`.
3. **SEO is built, not stubbed.** Editable meta/OG per page, auto-regenerating sitemap, structured data, canonical URLs, and slug-change redirects ship with the CMS — see [references/seo.md](references/seo.md). "We can add SEO later" means the CMS failed its main production purpose.

## Workflow

### Phase 1 — Discovery (read, don't ask yet)
Analyze the codebase before asking anything: framework, rendering mode (SSG/SSR/SPA), database (or none), hosting, existing auth, and a full inventory of routes and hardcoded content. → [references/discovery.md](references/discovery.md)

### Phase 2 — Interview the user
Ask the question set in [references/discovery.md](references/discovery.md#interview), pre-filled with what discovery found ("I see you're on Next.js + Supabase — should the CMS use the same database?"). Cover: who edits, which pages are CMS-driven, drafts/publishing, media storage, localization, admin location, and database choice if none exists. Keep it to one focused round of questions.

### Phase 3 — Content model + field map
Design collections, singletons, a shared SEO field group, and global site settings from the front-end inventory. Write `FIELD-MAP.md` mapping every front-end field to its CMS field. → [references/content-modeling.md](references/content-modeling.md)

### Phase 4 — Build the CMS
Schema/migrations, content API, and the Webflow-like admin UI (sidebar of pages + collections, editor with Content/SEO tabs, SERP preview, media library, draft → publish). → [references/admin-ui.md](references/admin-ui.md)

### Phase 5 — Wire the front end
Replace hardcoded content with CMS reads, page by page, updating `FIELD-MAP.md` status as you go. Preserve (or introduce) server rendering — CMS content fetched client-side is invisible to crawlers.

### Phase 6 — SEO layer
Implement the full checklist in [references/seo.md](references/seo.md): meta/OG editing, sitemap, robots, JSON-LD, canonicals, redirect manager with automatic slug-change redirects, alt-text enforcement.

### Phase 7 — Verify
- Every `FIELD-MAP.md` row is `wired`; grep confirms no leftover hardcoded copy.
- Build passes; edit → publish → live-site-change round-trip works.
- `curl` a page as a bot: content and meta tags present in the HTML response.
- Sitemap validates and includes every published page; changed slug 301s.

## Quick Reference

| Situation | Do |
|---|---|
| App is a client-only SPA (Vite/CRA) | Raise it in the interview — SEO needs prerendering/SSR; propose static generation or framework migration path |
| App has no database | Interview decides: SQLite for simple hosts, Postgres/Supabase for serverless |
| App already has a database | CMS tables live alongside it, prefixed (e.g. `cms_`) — never restructure app tables |
| User wants only some pages editable | Fine — but those pages' fields must be 100% mapped; note excluded pages in `FIELD-MAP.md` |
| Existing auth in the app | Reuse it with an editor/admin role; don't build a second login |

## Red Flags — Stop

- Writing schema or admin code before the interview is answered
- A page whose content you never inventoried
- "I'll map the remaining fields after the build works"
- SEO fields that exist in the schema but render nowhere
- CMS content that only appears after client-side JavaScript runs

## Common Mistakes

| Mistake | Fix |
|---|---|
| Modeling by content type you imagined, not pages that exist | Extract the model from the route/component inventory |
| One giant `pages` table with JSON blobs | Typed fields per collection/singleton — editors need real inputs, not JSON |
| Slug edits silently 404 old URLs | Auto-create a 301 redirect on every slug change |
| Admin UI lists raw DB rows | Webflow-like: human labels, grouped fields, SERP preview, publish state |
| Rich text stored as HTML with no sanitization | Store structured rich text (or sanitize on save and render) |
