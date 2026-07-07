# cms-skills

Agent skills that retrofit a **Webflow-like, SEO-ready CMS** onto any vibe-coded app.

Vibe-coded apps ship with a great front end and content hardcoded in components. The moment they hit production, someone needs to change a headline, swap an image, or publish a blog post — without a developer and without a redeploy. This skill teaches your coding agent to build that layer properly:

- **Reads your site first** — analyzes the framework, database, and every route to extract the content model from the pages that actually exist
- **Interviews you** — asks a short, targeted set of questions (editors, publishing workflow, media, database) before writing any code
- **Maps every field** — produces a `FIELD-MAP.md` contract so every user-visible string, image, link, and list on the site is editable from the CMS
- **Webflow-like admin** — pages + collections sidebar, Content/SEO tabs, media library, draft → publish, live preview
- **SEO built in, not bolted on** — editable meta/OG per page, SERP preview, auto-regenerating sitemap, robots.txt, JSON-LD structured data, canonical URLs, and automatic 301 redirects on slug changes

Works with your existing stack: the CMS lives in your app and your database (Next.js, Astro, Nuxt, SvelteKit, React SPAs with a prerendering plan, etc.).

## Install

```bash
npx skills add thabxi/cms-skills
```

Or install manually — copy `skills/cms-builder/` into your agent's skills directory:

| Agent | Path |
|---|---|
| Claude Code | `~/.claude/skills/` (or `.claude/skills/` in a project) |
| Codex / Copilot CLI / Gemini CLI | `~/.agents/skills/` |
| Cursor | `.cursor/skills/` in a project |

## Use

In your app's repo, ask your agent something like:

> Add a CMS to this site so I can edit all the content and manage SEO in production.

The `cms-builder` skill triggers, analyzes your codebase, asks you a few questions, and builds the CMS end to end. It finishes by verifying that every mapped field is wired and that pages, meta tags, sitemap, and redirects all work as a crawler sees them.

## Skills in this repo

| Skill | Use when |
|---|---|
| [`cms-builder`](skills/cms-builder/SKILL.md) | A front-end-first app needs editable content, an admin panel, or production SEO |

## License

[MIT](LICENSE)
