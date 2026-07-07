---
name: build-cms
description: Use when a vibe-coded or front-end-first app needs a content management system — hardcoded text/images must become editable, content needs managing in production without redeploys, the user asks for an admin panel or "CMS like Webflow", or the site must become SEO-ready with editable meta tags, sitemaps, and structured data. Invocable directly as /build-cms to run the whole build end to end.
---

# Build CMS

## Overview

Retrofit a Webflow-like CMS onto an existing app. The app already has a front end (usually vibe-coded, content hardcoded in components); this skill adds a database-backed content layer, a secure admin UI for editors, and production-grade SEO — then rewires the front end so **every content field comes from the CMS**.

**Core principle: the front end is the spec.** You do not invent a content model — you extract it from the existing pages, confirm it with the user, and map every field. A CMS that covers 80% of the site's content is a failed CMS: editors will still need a developer.

## Operating Contract — Fire and Forget

This skill runs as a single command (`/build-cms`) that finishes the job. User input happens at exactly **two checkpoints**:

1. **Interview** (Phase 2) — one batched round of questions.
2. **Architecture pick** (Phase 3) — user chooses from 2–3 proposed options.

After the architecture pick, run Phases 4–9 to completion **without asking anything else**. Decisions that come up mid-build are made autonomously using the defaults in the reference files and recorded in the final report's "Decisions made" section. The only exceptions that justify stopping: a missing credential/secret you cannot generate, or an action that would destroy existing user data.

Track the phases with your task list so progress is visible, and end with the Final Report (format below) — never with "let me know if you want me to continue."

**Branch safety:** Phases 1–3 are read-only. Before the first code change (Phase 4), create a `cms/build` branch and commit at every phase boundary — a failed run must be one checkout away from undone. Never build on the default branch, and never touch files unrelated to the CMS retrofit.

## The Iron Rules

1. **Interview before you build.** Complete Phases 1–3 before writing any schema or admin code. Do not scaffold "a reasonable CMS" and adjust later — the answers change the architecture (auth, database, rendering, publishing).
2. **No unmapped fields, no empty fields.** Produce `FIELD-MAP.md` before building. Every user-visible string, image, link, and list on every page appears in it, and every field is **seeded with the site's current content** when wired — the retrofit must not change what visitors see. The build is done only when every row is `wired`.
3. **SEO is built, not stubbed.** Editable meta/OG per page, auto-regenerating sitemap, structured data, canonicals, and slug-change redirects ship with the CMS — see [references/seo.md](references/seo.md).
4. **Security is built in, not reviewed in.** Every applicable control in [references/security.md](references/security.md) ships with the build, and Phase 9 actively probes for the failures it lists. An admin panel is an attack surface on a production site.

## Workflow

### Phase 1 — Discovery (read, don't ask yet)
Analyze the codebase: framework, rendering mode (SSG/SSR/SPA), database (or none), hosting, existing auth, media handling, and a full inventory of routes and hardcoded content. → [references/discovery.md](references/discovery.md)

### Phase 2 — Interview *(checkpoint 1)*
Ask the question set in [references/discovery.md](references/discovery.md#interview), pre-filled with discovery findings. Covers editors, scope, database, publishing workflow, media, auth, localization, new content types, SEO baseline. One focused round.

### Phase 3 — Architecture proposal *(checkpoint 2, last user input)*
Based on the detected stack, present 2–3 concrete options for **where the CMS lives and how it's accessed** (embedded `/admin`, separate admin app, embedded headless CMS; path vs subdomain; extra access layers), each with trade-offs and one marked recommended. → [references/architecture.md](references/architecture.md)

### Phase 4 — Content model + field map
Design collections, singletons, the shared SEO field group, and global site settings from the front-end inventory. Write `FIELD-MAP.md` mapping every front-end field to its CMS field. → [references/content-modeling.md](references/content-modeling.md)

### Phase 5 — Build the CMS
Schema/migrations, validated content API, and the Webflow-like admin UI (sidebar of pages + collections, editor with Content/SEO tabs, SERP preview, media library, draft → publish). Security controls (authz on every endpoint, input validation, upload hardening, CSRF, headers) are written **with** this code, not after it. → [references/admin-ui.md](references/admin-ui.md), [references/security.md](references/security.md)

### Phase 6 — Wire the front end
Before touching the first page, **snapshot the site**: run the app and save each route's rendered HTML (curl each route to a file) — this is the Phase 9 parity baseline. Then, page by page: **seed first, wire second** — insert the page's current hardcoded values into the CMS, then replace the hardcoded code with CMS reads, updating `FIELD-MAP.md` status as you go. Seeding lives in a committed seed script/migration, not ad-hoc inserts, so fresh environments get the content too. Preserve (or introduce) server rendering — CMS content fetched client-side is invisible to crawlers.

### Phase 7 — SEO layer
Implement the full checklist in [references/seo.md](references/seo.md): meta/OG editing, sitemap, robots, JSON-LD, canonicals, redirect manager with automatic slug-change redirects, alt-text enforcement.

### Phase 8 — Hardening + quality gates
Work through the [references/security.md](references/security.md) checklist item by item, then run the quality gates — all must pass:
- Typecheck and lint clean; production build succeeds.
- Targeted tests for the critical paths: auth guard on mutations, publish flow (draft invisible → published visible), slug-change → 301.
- Admin round-trip by hand: log in → edit → preview draft → publish → change appears on the live page; browser console free of errors.

### Phase 9 — Verify + report
- Every `FIELD-MAP.md` row is `wired`; grep confirms no leftover hardcoded copy.
- **Content parity:** diff each route's rendered output against the Phase 6 snapshot — visible content must be identical. The only acceptable deltas are intended additions (new meta/OG tags, JSON-LD); any changed or missing copy is a seeding bug, not a note for the report.
- Crawler checks: `curl` a page as a bot — content, meta tags, and JSON-LD present in raw HTML; sitemap valid and complete; changed slug 301s; `/admin` blocked and noindexed.
- Security probes from [references/security.md](references/security.md#verification): unauthenticated mutation rejected, upload of disguised file rejected, XSS payload in rich text rendered inert, no secrets in the client bundle.
- Deliver the Final Report.

## Final Report (required structure)

End the run with exactly these sections:

1. **What was built** — architecture chosen, collections/singletons created, pages wired.
2. **Access** — admin URL, how to log in, where credentials live (never print a password that should be secret; say where it was stored).
3. **Decisions made autonomously** — every default applied after checkpoint 2, one line each.
4. **Field map** — total fields, all `wired` (or the explicit exclusion list from the interview).
5. **Verification results** — quality gates, crawler checks, and security probes, with pass/fail evidence.
6. **Limitations & next steps** — anything deferred, with a recommendation.

## Quick Reference

| Situation | Do |
|---|---|
| App is a client-only SPA (Vite/CRA) | Raise in the interview — SEO needs prerendering/SSR; the architecture proposal must include a rendering plan |
| App has no database | Interview decides: SQLite for simple hosts, Postgres/Supabase for serverless |
| App already has a database | CMS tables live alongside it, prefixed `cms_` — never restructure app tables |
| User wants only some pages editable | Fine — those pages' fields must be 100% mapped; note exclusions in `FIELD-MAP.md` |
| Existing auth in the app | Reuse it with an editor/admin role; don't build a second login |
| A previous `/build-cms` run detected (`FIELD-MAP.md`, `cms_` tables) | **Extend mode**: diff the field map against the current front end and add only what's missing — never drop or rebuild existing `cms_` tables |
| A third-party CMS detected (Sanity, Contentful, WordPress, Payload, Strapi…) | Don't build a competing CMS — surface it at the interview: extend it, migrate off it, or scope this build to the unmanaged parts. User decides |
| User can't decide at checkpoint 2 | Take the recommended option, say so, proceed |
| Mid-build uncertainty (naming, library choice, field grouping) | Decide using reference defaults, log it in the report — do not ask |

## Red Flags — Stop

- Writing schema or admin code before checkpoint 2 is answered
- A third round of questions to the user
- A page whose content you never inventoried
- "I'll map the remaining fields after the build works"
- SEO fields that exist in the schema but render nowhere
- CMS content that only appears after client-side JavaScript runs
- A mutation endpoint whose only protection is a client-side route guard
- A second CMS being scaffolded next to one that already exists
- A wired page rendering different copy than the pre-build snapshot
- CMS code being written on the default branch
- Ending the run without the Final Report

## Common Mistakes

| Mistake | Fix |
|---|---|
| Modeling by content type you imagined, not pages that exist | Extract the model from the route/component inventory |
| One giant `pages` table with JSON blobs | Typed fields per collection/singleton — editors need real inputs, not JSON |
| Slug edits silently 404 old URLs | Auto-create a 301 redirect on every slug change |
| Admin UI lists raw DB rows | Webflow-like: human labels, grouped fields, SERP preview, publish state |
| Rich text stored as raw HTML, rendered unsanitized | Store structured rich text, or sanitize server-side with a strict allowlist |
| Security added as a final review pass | Controls are written with each endpoint/upload/form as it's built (Iron Rule 4) |
| Fields wired but the database left empty | Seed first, wire second — the site must render its current content from the CMS immediately |
| Service-role/DB credentials reachable from the client bundle | Server-only env access; verify by grepping the built client output |
