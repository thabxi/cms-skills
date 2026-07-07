/**
 * Starter Zod schemas for the CMS field types (see references/content-modeling.md
 * and references/security.md). One shared module, imported by BOTH the field
 * editors (client) and every mutation endpoint (server), so the API can't be
 * used to bypass what the UI enforces. Adapt names/limits to the project.
 */
import { z } from "zod";

/** URL-safe slug; rejects traversal, slashes, and unicode tricks (security.md). */
export const slug = z
  .string()
  .min(1)
  .max(120)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Lowercase letters, numbers, and hyphens only");

/**
 * SEO field group, attached to every page-like entity.
 * Hard caps sit above the UI warning thresholds (60/160) on purpose:
 * counters warn, schemas only block the absurd (seo.md).
 */
export const seoFields = z.object({
  meta_title: z.string().max(120).default(""),
  meta_description: z.string().max(320).default(""),
  og_image_id: z.string().uuid().nullable().default(null),
  canonical_url: z.union([z.literal(""), z.string().url()]).default(""),
  noindex: z.boolean().default(false),
});

/** Image field = media reference + REQUIRED alt text (blocks save when empty). */
export const imageField = z.object({
  media_id: z.string().uuid(),
  alt: z.string().trim().min(1, "Alt text is required"),
});

/** Link field; internal hrefs should additionally be validated against real routes. */
export const linkField = z.object({
  label: z.string().trim().min(1),
  href: z
    .string()
    .trim()
    .min(1)
    .refine(
      (v) => v.startsWith("/") || /^https?:\/\//.test(v) || v.startsWith("mailto:"),
      "Must be a relative path, http(s) URL, or mailto:"
    ),
  external: z.boolean().default(false),
});

/** Publishable-entity base: spread into every collection with its own URL. */
export const publishable = z.object({
  slug,
  status: z.enum(["draft", "published"]).default("draft"),
  published_at: z.coerce.date().nullable().default(null),
});

/**
 * Redirect target: relative path or same-origin only — an open redirect is an
 * SEO and phishing hole (security.md). Set SITE_ORIGIN from env at the call site.
 */
export const redirectTarget = (siteOrigin: string) =>
  z
    .string()
    .trim()
    .refine(
      (v) => v.startsWith("/") || v.startsWith(siteOrigin + "/") || v === siteOrigin,
      "Redirects must stay on this site"
    );

/** Example collection entry composing the pieces. */
export const postSchema = publishable.extend({
  title: z.string().trim().min(1).max(200),
  body: z.unknown(), // structured rich text JSON (Tiptap/ProseMirror) — sanitize if ever rendered as HTML
  hero: imageField.nullable().default(null),
  seo: seoFields,
});
export type Post = z.infer<typeof postSchema>;
