# Discovery & Interview

Phase 1 is read-only codebase analysis. Phase 2 is one focused round of user questions, pre-filled with what you found. Never ask something the codebase already answers.

## Phase 1 — Codebase analysis

Establish these facts, with file evidence for each:

| Fact | How to find it |
|---|---|
| Framework & version | `package.json` deps: `next`, `astro`, `nuxt`, `@sveltejs/kit`, `react-router` / `vite` alone (SPA), or plain HTML |
| Rendering mode | Next: `output` config, `generateStaticParams`, `"use client"` density. Vite/CRA with no SSR framework = client-only SPA (flag for SEO) |
| Database | Env vars (`DATABASE_URL`, `SUPABASE_URL`, `MONGODB_URI`), ORM configs (`prisma/schema.prisma`, `drizzle.config.*`), or none |
| Existing auth | Auth libraries (`next-auth`, `@supabase/auth-*`, `clerk`, `lucia`), login routes, session middleware |
| Hosting | `vercel.json`, `netlify.toml`, Dockerfile, `wrangler.toml`, CI workflows |
| Media handling | Existing upload code, `public/` image usage, image CDN references |
| i18n | Locale routing, i18n libraries, hardcoded multi-language strings |

### Content inventory

Enumerate every route (pages/app directory, router config, or HTML files). For each route, walk its component tree and record every user-visible content element:

- **Text**: headings, paragraphs, button labels, nav items, footer copy
- **Media**: images (src + alt), videos, icons that editors might swap
- **Links**: internal links, CTAs, social URLs
- **Lists**: repeated blocks (testimonials, features, FAQ items, team cards, blog posts) — these become collections
- **Metadata**: existing `<title>`, meta description, OG tags (often missing — note that)

Record file and line for each. This inventory becomes the left column of `FIELD-MAP.md` (see content-modeling.md) — do it thoroughly once, not incrementally during the build.

Distinguish **content** (an editor would change it: hero headline, pricing copy) from **UI chrome** (structural microcopy: "Submit", "Loading…", validation messages). Default: chrome stays in code. List borderline items for the interview.

## Phase 2 — Interview {#interview}

Ask in one round, pre-filled with discovery findings. Skip any question discovery already answered decisively.

1. **Editors** — Who edits content? Just you, a team, non-technical clients? (Determines auth strictness, UI polish, roles.)
2. **Scope** — Which pages/sections should be CMS-driven? Everything, or marketing pages only? Confirm the chrome/content borderline items from discovery.
3. **Database** — *(if none exists)* Preference? Recommend based on hosting: serverless host → Postgres (Supabase/Neon); single server → SQLite. *(if one exists)* Confirm CMS tables live alongside it.
4. **Publishing** — Draft → publish workflow, or edits go live immediately? Scheduled publishing needed?
5. **Media** — Where should uploaded images live? (Existing bucket, Supabase Storage, S3, Cloudinary, local `public/`.)
6. **Admin location** — `/admin` route inside the app (recommended: shares components and deploys), or a separate app?
7. **Auth** — *(if app has auth)* Reuse it with an editor role? *(if not)* Single admin password, or proper accounts?
8. **Localization** — One language or several? (Changes the schema shape — ask before modeling.)
9. **Blog/collections growth** — Any new content types wanted beyond what the site shows today (blog, careers, changelog)? Retrofit is the cheap moment to add them.
10. **SEO baseline** — Any existing SEO investment (Search Console, current rankings, redirect lists from an old site) the CMS must preserve?

If the app is a **client-only SPA**, add: "CMS content rendered client-side won't be seen by search crawlers. Options: (a) prerender/SSG the public pages, (b) migrate to a framework with SSR (e.g. Vite React → React Router/Next), (c) accept weak SEO for now. Which do you want?" Do not silently pick one.

Summarize the agreed architecture in 5–8 bullet points back to the user before starting Phase 3.
