#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

EVENTS_JSON="${EVENTBUDDY_EVENTS_JSON:-"$ROOT_DIR/EventBuddy/events.json"}"
WRANGLER="$ROOT_DIR/node_modules/.bin/wrangler"
TARGET="${1:-${EVENTBUDDY_EVENTS_TARGET:-r2}}"

usage() {
  cat <<'USAGE'
Usage:
  npm run publish:events -- r2
  npm run publish:events -- pages
  npm run publish:events -- kv

Targets:
  r2     Upload EventBuddy/events.json to an R2 object.
         Required: EVENTBUDDY_R2_BUCKET or CLOUDFLARE_R2_BUCKET
         Optional: EVENTBUDDY_R2_OBJECT_KEY, EVENTBUDDY_R2_CACHE_CONTROL

  pages  Deploy a feed-only Cloudflare Pages project containing events.json.
         Required: EVENTBUDDY_PAGES_PROJECT or CLOUDFLARE_PAGES_PROJECT
         Optional: EVENTBUDDY_PAGES_BRANCH

  kv     Put events.json into Workers KV.
         Required: EVENTBUDDY_KV_NAMESPACE_ID or CLOUDFLARE_KV_NAMESPACE_ID
         Optional: EVENTBUDDY_KV_KEY

Examples:
  EVENTBUDDY_R2_BUCKET=eventbuddy-feed npm run publish:events -- r2
  EVENTBUDDY_PAGES_PROJECT=eventbuddy-feed npm run publish:events -- pages
  EVENTBUDDY_KV_NAMESPACE_ID=xxxxxxxx npm run publish:events -- kv
USAGE
}

die() {
  echo "error: $*" >&2
  echo >&2
  usage >&2
  exit 64
}

if [[ "$TARGET" == "-h" || "$TARGET" == "--help" || "$TARGET" == "help" ]]; then
  usage
  exit 0
fi

case "$TARGET" in
  r2|pages|kv) ;;
  *) die "Unknown target: $TARGET" ;;
esac

if [[ ! -x "$WRANGLER" ]]; then
  die "Wrangler is not installed. Run npm install first."
fi

if [[ ! -f "$EVENTS_JSON" ]]; then
  die "Could not find events JSON at $EVENTS_JSON"
fi

node - "$EVENTS_JSON" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
const data = JSON.parse(fs.readFileSync(path, "utf8"));

if (!Array.isArray(data.events)) {
  throw new Error("events must be an array");
}

if (typeof data.lastUpdated !== "string" || typeof data.version !== "string") {
  throw new Error("events JSON must include lastUpdated and version strings");
}

console.log(`Validated ${data.events.length} events from ${path}`);
console.log(`Version: ${data.version}`);
console.log(`Last updated: ${data.lastUpdated}`);
NODE

case "$TARGET" in
  r2)
    bucket="${EVENTBUDDY_R2_BUCKET:-${CLOUDFLARE_R2_BUCKET:-}}"
    object_key="${EVENTBUDDY_R2_OBJECT_KEY:-events.json}"
    cache_control="${EVENTBUDDY_R2_CACHE_CONTROL:-public, max-age=300}"

    [[ -n "$bucket" ]] || die "Set EVENTBUDDY_R2_BUCKET or CLOUDFLARE_R2_BUCKET."

    "$WRANGLER" r2 object put "$bucket/$object_key" \
      --remote \
      --file "$EVENTS_JSON" \
      --content-type application/json \
      --cache-control "$cache_control"
    ;;

  pages)
    project="${EVENTBUDDY_PAGES_PROJECT:-${CLOUDFLARE_PAGES_PROJECT:-}}"
    branch="${EVENTBUDDY_PAGES_BRANCH:-main}"

    [[ -n "$project" ]] || die "Set EVENTBUDDY_PAGES_PROJECT or CLOUDFLARE_PAGES_PROJECT."

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT
    cp "$EVENTS_JSON" "$temp_dir/events.json"

    "$WRANGLER" pages deploy "$temp_dir" \
      --project-name "$project" \
      --branch "$branch" \
      --commit-dirty=true
    ;;

  kv)
    namespace_id="${EVENTBUDDY_KV_NAMESPACE_ID:-${CLOUDFLARE_KV_NAMESPACE_ID:-}}"
    key="${EVENTBUDDY_KV_KEY:-events.json}"

    [[ -n "$namespace_id" ]] || die "Set EVENTBUDDY_KV_NAMESPACE_ID or CLOUDFLARE_KV_NAMESPACE_ID."

    "$WRANGLER" kv key put "$key" \
      --remote \
      --namespace-id "$namespace_id" \
      --path "$EVENTS_JSON"
    ;;

esac
