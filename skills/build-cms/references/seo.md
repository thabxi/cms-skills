# SEO Layer

Every item here ships with the CMS. Editors control SEO from the admin UI; nothing on this list requires a developer after launch. The whole layer is worthless if pages aren't server-rendered — settle rendering in the interview (discovery.md) before building any of this.

## Per-page (SEO field group, edited on the SEO tab)

| Feature | Implementation |
|---|---|
| Meta title | `<title>`; fallback pattern `{page title} — {site name}` from Site Settings |
| Meta description | Editable, counter at 160 chars; fallback: excerpt of page content |
| Open Graph + Twitter card | `og:title/description/image/url/type`, `twitter:card=summary_large_image`; per-page image with global default fallback |
| Canonical URL | Auto: absolute URL of the page. Editable override for syndicated content |
| `noindex` toggle | Per page/entry; also emit in `X-Robots-Tag` for non-HTML |
| Slug management | Editable slugs; **on slug change of a published entry, write a 301 into `cms_redirects` in the same transaction** — old URLs must never 404 |

## Site-wide (generated / Site Settings)

| Feature | Implementation |
|---|---|
| `sitemap.xml` | Generated from published entries + static routes, with `lastmod` from `updated_at`. Regenerated (or served dynamically) on every publish. Excludes `noindex` pages and `/admin`. Referenced from robots.txt |
| `robots.txt` | Served from Site Settings (editable textarea with safe default); always disallow `/admin` |
| Redirect manager | `cms_redirects` (from_path, to_path, code) editable in admin; applied in middleware/server config **before** the 404 handler. Import list from an old site if the interview surfaced one |
| 404 page | Real 404 status code (not a soft-200 SPA fallback) with editable content |
| Structured data (JSON-LD) | `Organization` + `WebSite` on home; `Article` (headline, image, dates, author) on posts; `BreadcrumbList` on nested pages; `FAQPage` when an FAQ collection exists. Values from CMS fields — never hardcoded duplicates |
| Analytics / verification | Site Settings fields for GA4/other ID and search-engine verification meta tags |

## Content hygiene (enforced by the CMS, not documentation)

- **Alt text required**: image fields refuse to save without it (schema + server validation).
- **One `<h1>` per page**: page title field renders the `<h1>`; rich text editors offer h2+ only.
- **Image performance is SEO**: uploads resized/compressed; rendered via the framework's image component with width/height set (CLS) and lazy loading below the fold.
- Meta title/description counters warn beyond 60/160 chars but don't block.

## Localization (only if interview said multilingual)

`hreflang` alternates on every page, locale-suffixed sitemap entries, per-locale SEO fields, and locale-aware canonicals.

## Verification (final phase)

Automated by [../scripts/verify.sh](../scripts/verify.sh); the underlying checks:

```bash
# Meta + content present in raw HTML (as a crawler sees it)
curl -sA "Googlebot" https://site.tld/some-page | grep -E "og:title|application/ld\+json|<h1"

# Sitemap exists and includes a known published entry
curl -s https://site.tld/sitemap.xml | grep some-slug

# Changed slug redirects with 301, admin is blocked
curl -s -o /dev/null -w "%{http_code}" https://site.tld/old-slug     # → 301
curl -s https://site.tld/robots.txt | grep -i "disallow: /admin"
```

Validate one page of each type in Google's Rich Results Test (or `npx structured-data-testing-tool`) before calling SEO done.
