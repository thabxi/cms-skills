# Field Map

<!-- The contract for the whole build (Iron Rule 2). One section per route from the
     Phase 1 inventory, plus one per collection. Every user-visible string, image,
     link, and list gets a row. Copy this file to the repo root as FIELD-MAP.md. -->

Status legend: `planned` → `built` (in schema) → `wired` (front end reads from CMS, seeded with current content)

## Page: <Name> (`/<route>`) — singleton `<key>`

| Front-end element | Source (file:line) | CMS field | Type | Status |
|---|---|---|---|---|
| <element> | <src/pages/X.tsx:NN> | <key>.<field_name> | text | planned |

### SEO fields (`/<route>`)

| Field | CMS field | Status |
|---|---|---|
| Meta title | <key>.seo.meta_title | planned |
| Meta description | <key>.seo.meta_description | planned |
| OG image | <key>.seo.og_image | planned |

## Collection: <name>

<!-- Repeated blocks the front end .map()s over. Items with their own URL also
     need slug/status/published_at and an SEO section. -->

| Item field | CMS field | Type | Status |
|---|---|---|---|
| <field> | <name>.<field_name> | richtext | planned |

## Global settings (singleton `settings`)

| Field | CMS field | Type | Status |
|---|---|---|---|
| Site name | settings.site_name | text | planned |
| Default OG image | settings.default_og_image | image | planned |
| Social links | settings.social_links | repeater | planned |

## Excluded (UI chrome — stays in code, confirmed at checkpoint 1)

<!-- Structural microcopy the interview agreed to leave hardcoded. -->
- <e.g. form validation messages>
- <e.g. "Loading…" states>
