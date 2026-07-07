#!/usr/bin/env bash
# Phase 9 mechanical probes for build-cms (see SKILL.md Phase 9, references/seo.md,
# references/security.md#verification). Run against a deployed or locally served build.
#
# Usage:
#   ./verify.sh <site-url> [options]
# Options:
#   --admin-path <path>     Admin route to probe            (default: /admin)
#   --api-probe <path>      A CMS mutation endpoint to POST unauthenticated
#   --changed-slug <path>   An old path that should 301 after a slug change
#   --content-page <path>   A CMS-driven page to crawler-check (default: /)
#   --dist <dir>            Built client output to grep for leaked secrets (repeatable)
#
# Exit code: number of FAILs (0 = all passed). WARNs don't fail the run but go in the report.

set -u
BASE=""; ADMIN="/admin"; API=""; SLUG=""; PAGE="/"; DISTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --admin-path) ADMIN="$2"; shift 2;;
    --api-probe) API="$2"; shift 2;;
    --changed-slug) SLUG="$2"; shift 2;;
    --content-page) PAGE="$2"; shift 2;;
    --dist) DISTS+=("$2"); shift 2;;
    *) BASE="${1%/}"; shift;;
  esac
done
[ -n "$BASE" ] || { echo "Usage: $0 <site-url> [options]"; exit 1; }

UA="Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
PASS=0; FAIL=0; WARN=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
warn() { WARN=$((WARN+1)); printf 'WARN  %s\n' "$1"; }
code() { curl -s -o /dev/null -w '%{http_code}' -A "$UA" --max-time 20 "$1"; }

echo "== build-cms verify: $BASE =="

# --- Crawler visibility: content + meta in raw HTML ---
HTML=$(curl -s -A "$UA" --max-time 20 "$BASE$PAGE")
echo "$HTML" | grep -qi '<h1' \
  && ok "content page $PAGE has <h1> in raw HTML" \
  || bad "content page $PAGE: no <h1> in raw HTML — content may be client-rendered"
echo "$HTML" | grep -qi 'name="description"' \
  && ok "meta description present" || bad "meta description missing"
echo "$HTML" | grep -qi 'property="og:title"' \
  && ok "Open Graph tags present" || bad "og:title missing"
echo "$HTML" | grep -qi 'application/ld+json' \
  && ok "JSON-LD structured data present" || warn "no JSON-LD on $PAGE"

# --- Sitemap & robots ---
SM=$(curl -s -A "$UA" --max-time 20 "$BASE/sitemap.xml")
echo "$SM" | grep -qi '<urlset\|<sitemapindex' \
  && ok "sitemap.xml serves a valid urlset" || bad "sitemap.xml missing or invalid"
echo "$SM" | grep -qi "$ADMIN" \
  && bad "sitemap.xml contains admin routes" || ok "sitemap excludes admin"
RB=$(curl -s -A "$UA" --max-time 20 "$BASE/robots.txt")
echo "$RB" | grep -qiE "disallow: *$ADMIN" \
  && ok "robots.txt disallows $ADMIN" || bad "robots.txt does not disallow $ADMIN"

# --- Admin locked down ---
AC=$(code "$BASE$ADMIN")
case "$AC" in
  200) bad "anonymous GET $ADMIN returned 200 — admin is exposed";;
  30[1278]|401|403) ok "anonymous GET $ADMIN blocked ($AC)";;
  *) warn "anonymous GET $ADMIN returned $AC — confirm intent";;
esac
HDRS=$(curl -sI -A "$UA" --max-time 20 "$BASE$ADMIN")
echo "$HDRS" | grep -qi 'x-content-type-options: *nosniff' \
  && ok "admin sends X-Content-Type-Options: nosniff" || warn "admin missing nosniff header"
echo "$HDRS" | grep -qi 'content-security-policy\|x-frame-options' \
  && ok "admin sends CSP/frame protection" || warn "admin missing CSP/X-Frame-Options"

# --- Unauthenticated mutation ---
if [ -n "$API" ]; then
  MC=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -X POST -H 'Content-Type: application/json' -d '{}' "$BASE$API")
  case "$MC" in
    401|403) ok "unauthenticated POST $API rejected ($MC)";;
    2??) bad "unauthenticated POST $API succeeded ($MC) — missing server-side authz";;
    *) warn "unauthenticated POST $API returned $MC — verify it was rejected for auth, not shape";;
  esac
fi

# --- Slug-change redirect ---
if [ -n "$SLUG" ]; then
  RC=$(code "$BASE$SLUG")
  case "$RC" in
    301|308) ok "changed slug $SLUG permanent-redirects ($RC)";;
    302|307) warn "$SLUG redirects with $RC — should be 301/308 for SEO";;
    *) bad "changed slug $SLUG returned $RC — old URLs must 301";;
  esac
fi

# --- Soft-404 ---
NF=$(code "$BASE/definitely-not-a-real-page-$RANDOM")
[ "$NF" = "404" ] && ok "unknown path returns real 404" \
  || bad "unknown path returns $NF — soft-404s poison indexing"

# --- Secret leak grep in built client output ---
for D in ${DISTS[@]+"${DISTS[@]}"}; do
  if [ -d "$D" ]; then
    if grep -rlEI 'SERVICE_ROLE|DATABASE_URL|SUPABASE_SERVICE|BEGIN (RSA )?PRIVATE KEY' "$D" >/dev/null 2>&1; then
      bad "possible server secret in client bundle: $D (grep SERVICE_ROLE/DATABASE_URL)"
    else
      ok "no server secrets found in $D"
    fi
  else
    warn "dist dir not found: $D"
  fi
done

echo "== $PASS passed, $FAIL failed, $WARN warnings =="
echo "Manual checks still required: disguised-file upload rejected, XSS payload inert,"
echo "draft URL blocked without preview token, content parity vs .cms-snapshot/."
exit "$FAIL"
