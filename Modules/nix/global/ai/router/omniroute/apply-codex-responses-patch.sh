#!/bin/sh
# Apply our pinned OmniRoute compatibility patch after npx has realized the
# requested package. Package caches are disposable, so this is deliberately
# idempotent and runs before every OmniRoute launch.
set -eu

cache_root="${OMNIROUTE_NPX_CACHE:?OMNIROUTE_NPX_CACHE is required}/npm-cache/_npx"
patch_file="${OMNIROUTE_CODEX_RESPONSES_PATCH:?OMNIROUTE_CODEX_RESPONSES_PATCH is required}"

applied=0
for package_dir in "$cache_root"/*/node_modules/omniroute; do
  [ -f "$package_dir/open-sse/translator/request/openai-responses/toResponses.ts" ] || continue

  target="$package_dir/open-sse/translator/request/openai-responses/toResponses.ts"
  if grep -Fq 'Hermes can use the generic `{ enabled: boolean }`' "$target"; then
    applied=1
    continue
  fi

  patch --batch --forward -p1 -d "$package_dir" < "$patch_file"
  applied=1
done

[ "$applied" -eq 1 ] || {
  printf '%s\n' 'OmniRoute package was not found in the npx cache after realization.' >&2
  exit 1
}
