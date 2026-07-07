# Content Modeling & Field Mapping

The model is extracted from the front end, not designed in the abstract. Every element in the Phase 1 content inventory lands in exactly one place in the model.

## Model shapes

| Shape | Use for | Examples |
|---|---|---|
| **Singleton** | One-off page or section content | Homepage hero, About page, footer, nav |
| **Collection** | Repeated items with the same shape | Blog posts, testimonials, team members, FAQ items, features |
| **Global settings** (singleton) | Site-wide values | Site name, logo, default OG image, social links, analytics IDs, robots directives |
| **SEO field group** | Reusable group attached to every page-like entity | Meta title, meta description, OG image, canonical, noindex |

Rules of thumb:
- If the front end `.map()`s over it, or there are 2+ visually identical blocks — it's a collection.
- If a collection item has its own URL (blog post), it needs `slug`, `status`, `published_at`, and the SEO field group.
- Repeated sections *within* a page (e.g. alternating feature rows) can be a repeater field on the singleton instead of a full collection — prefer the repeater when items are never shared across pages.

## Field types

Use typed fields; never a single JSON blob the editor edits raw.

| Type | Notes |
|---|---|
| `text` | Single line. Set `max_length` where layout breaks (hero headline) |
| `richtext` | Structured (Tiptap/ProseMirror JSON or portable text) — not raw HTML |
| `image` | Reference to media library entry; **alt text required at the schema level** |
| `link` | `{ label, href, external }` — validate internal hrefs against real routes |
| `select` / `boolean` / `number` / `date` | As needed |
| `reference` | FK to another collection (post → author) |
| `repeater` | Ordered list of a fixed sub-field group |

Naming: field names mirror what the editor sees on the page (`hero_headline`, `cta_label`), not developer jargon (`text_1`, `content_block_a`).

## FIELD-MAP.md (required artifact)

Create it at the repo root at the end of Phase 3, before any build code. It is the contract for the whole build and the Phase 7 checklist.

```markdown
# Field Map

Status: `planned` → `built` (in schema) → `wired` (front end reads from CMS)

## Page: Home (`/`) — singleton `home`
| Front-end element | Source (file:line) | CMS field | Type | Status |
|---|---|---|---|---|
| Hero headline | src/pages/Home.tsx:24 | home.hero_headline | text | planned |
| Hero image | src/pages/Home.tsx:31 | home.hero_image | image | planned |
| Testimonials | src/components/Testimonials.tsx:12 | collection: testimonials | — | planned |

## Collection: testimonials
| Item field | CMS field | Type | Status |
|---|---|---|---|
| Quote | testimonials.quote | richtext | planned |
| Author name | testimonials.author | text | planned |

## Excluded (UI chrome — stays in code, confirmed in interview)
- Form validation messages
- "Loading…" states
```

Every route from the inventory gets a section — including its SEO fields. If a row can't be placed, that's a modeling gap: fix the model, don't drop the row.

## Schema conventions

- Prefix CMS tables in a shared database: `cms_pages`, `cms_testimonials`, `cms_media`, `cms_redirects`, `cms_settings`.
- Every publishable entity: `status` (`draft`/`published`), `published_at`, `updated_at`. If drafts were requested, read queries on the public site filter `status = 'published'`; the admin preview reads drafts.
- Slugs: unique, URL-safe, auto-generated from title but editable. On slug change, insert a row into `cms_redirects` (see seo.md) in the same transaction.
- Media: one `cms_media` table (url, alt, width, height, mime, size); image fields reference it rather than storing bare URLs.
- Migrations go through the app's existing migration tool (Prisma/Drizzle/Supabase migrations). Never mutate existing app tables.
