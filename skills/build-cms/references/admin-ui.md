# Admin UI — Webflow-like Editor

The bar: a non-technical editor opens `/admin` and understands it without training. Webflow-like means content-first navigation, human labels, visible publish state, and instant feedback — not a database browser.

## Layout

```
┌────────────┬──────────────────────────────┬─────────────┐
│  Sidebar   │  Editor                      │  (optional) │
│            │                              │  Preview    │
│  PAGES     │  Home                        │             │
│  • Home    │  [Content] [SEO]   ● Draft   │  live       │
│  • About   │                              │  rendered   │
│  COLLECT.  │  Hero headline               │  page       │
│  • Blog    │  [___________________]       │             │
│  • Team    │  Hero image                  │             │
│  SETTINGS  │  [thumb] [Replace]           │             │
│  MEDIA     │                              │             │
│            │        [Save draft] [Publish]│             │
└────────────┴──────────────────────────────┴─────────────┘
```

- **Sidebar**: Pages (singletons) and Collections listed by human name, plus Media and Site Settings. Order matches the site's nav, not the schema.
- **Collection list view**: title, status badge, updated date; search; "New" button. No raw IDs.
- **Editor**: fields in page order (same order the visitor sees), grouped under **Content** and **SEO** tabs. Field labels from `FIELD-MAP.md` element names, with a short help text where ambiguous ("Shown in the top banner of the homepage").

## Field editors

| Field | Editor behavior |
|---|---|
| text | Input with live character count when `max_length` set |
| richtext | Toolbar editor (Tiptap or equivalent): headings, bold, links, lists, images from media library |
| image | Picker over the media library + upload; **alt text input blocks save when empty** |
| link | Label + URL; internal URLs validated against real routes |
| repeater | Add / remove / drag-reorder items |
| slug | Auto-fills from title, editable; on change of a published entry, show "Old URL will redirect" notice |

## SEO tab (every page-like entity)

- Meta title + description with character counters (≤ 60 / ≤ 160) and a **SERP preview** (rendered Google-style snippet).
- OG image picker with social-card preview; falls back to the global default from Site Settings.
- Canonical URL override, `noindex` toggle.

## Publishing

- Explicit states: `Draft` / `Published` (+ "Published — unsaved changes" when a published entry has newer draft content, if drafts were requested in the interview).
- **Preview** renders the actual site page with draft content (draft-mode cookie or signed preview token) — not an approximation.
- Publish triggers whatever makes the change live: cache/ISR revalidation, static rebuild hook, or nothing extra for SSR. Also regenerates the sitemap (see seo.md).

## Auth

- Reuse the app's auth with an `editor`/`admin` role when it exists; otherwise the interview decided single-password or accounts.
- Every `/admin` route and every mutation endpoint checks the role **server-side** — plus sessions, CSRF, upload hardening, and validation per [security.md](security.md). Those controls are written with each piece of UI/API as it's built.

## Implementation notes

- Build wherever the checkpoint-2 pick put it ([architecture.md](architecture.md)); when embedded, use a route group (`app/(admin)/admin`) with the app's existing UI stack so styling and deploys are shared. Admin routes are always `noindex` and excluded from the sitemap.
- Validate writes server-side with a shared schema (e.g. Zod) — same rules the field editors enforce, so the API can't be used to bypass alt-text or length requirements.
- Autosave drafts or warn on navigation with unsaved changes; editors lose work silently otherwise.
- Media library: grid view, upload with automatic resize/compression to sane web sizes, edit alt text in place, show which entries use an asset before delete.
