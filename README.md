# cms-skills

**`/build-cms`** — a fire-and-forget agent skill that retrofits a **Webflow-like, secure, SEO-ready CMS** onto any vibe-coded app.

Vibe-coded apps ship with a great front end and content hardcoded in components. The moment they hit production, someone needs to change a headline, swap an image, or publish a blog post — without a developer and without a redeploy. This skill teaches your coding agent to build that layer properly, end to end, in a single run:

- **Reads your site first** — analyzes the framework, database, rendering mode, and every route to extract the content model from the pages that actually exist
- **Two checkpoints, then hands-off** — one batched interview (editors, publishing, media, database), then an architecture proposal with 2–3 options for *where the CMS lives and how it's accessed* (embedded `/admin`, separate admin app, or an embedded headless CMS), tailored to your stack with a recommendation. After you pick, it runs to completion and ends with a full report — no drip-fed questions
- **Maps every field** — produces a `FIELD-MAP.md` contract so every user-visible string, image, link, and list on the site is editable from the CMS
- **Webflow-like admin** — pages + collections sidebar, Content/SEO tabs, media library, draft → publish, live preview, SERP preview
- **SEO built in, not bolted on** — editable meta/OG per page, auto-regenerating sitemap, robots.txt, JSON-LD structured data, canonical URLs, automatic 301 redirects on slug changes
- **Security-controlled by construction** — server-side authz on every endpoint, shared input validation, sanitized rich text, magic-byte upload checks, CSRF and security headers, audit log, and a final pass of active security probes (unauthenticated writes, disguised uploads, XSS payloads, secret-leak grep of the client bundle)
- **Quality gates before handoff** — typecheck, lint, build, targeted tests for auth guards / publish flow / redirects, and crawler-eye verification (`curl` as a bot) before the skill calls itself done

Works with your existing stack: the CMS lives in your app and your database (Next.js, Astro, Nuxt, SvelteKit, React SPAs with a prerendering plan, etc.).

## Install

```bash
npx skills add thabxi/cms-skills
```

Or install manually — copy `skills/build-cms/` into your agent's skills directory:

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/skills/` (or `.claude/skills/` in a project) |
| Codex / Copilot CLI / Gemini CLI | `~/.agents/skills/` |
| Cursor | `.cursor/skills/` in a project |

## Use

In your app's repo, invoke it directly:

```
/build-cms
```

or just ask:

> Add a CMS to this site so I can edit all the content and manage SEO in production.

The agent analyzes your codebase, asks one round of questions, proposes where the CMS should live, and after your pick builds everything — schema, admin UI, front-end wiring, SEO, and security hardening — finishing with a report covering what was built, how to access it, every autonomous decision made, and the verification/security-probe results.

## Skills in this repo

| Skill | Use when |
|---|---|
| [`build-cms`](skills/build-cms/SKILL.md) | A front-end-first app needs editable content, an admin panel, or production SEO |

## License

[MIT](LICENSE)
