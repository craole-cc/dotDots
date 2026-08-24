#!/bin/sh
# Apply pinned OmniRoute compatibility patches after npx realizes the package.
# Package caches are disposable, so each patch is idempotent and reapplied as needed.
set -eu

cache_root="${OMNIROUTE_NPX_CACHE:?OMNIROUTE_NPX_CACHE is required}/npm-cache/_npx"
translator_patch="${OMNIROUTE_CODEX_RESPONSES_PATCH:?OMNIROUTE_CODEX_RESPONSES_PATCH is required}"
executor_patch="${OMNIROUTE_CODEX_EXECUTOR_PATCH:?OMNIROUTE_CODEX_EXECUTOR_PATCH is required}"
target_patch="${OMNIROUTE_CODEX_TARGET_PATCH:?OMNIROUTE_CODEX_TARGET_PATCH is required}"
serialization_patch="${OMNIROUTE_CODEX_SERIALIZATION_PATCH:?OMNIROUTE_CODEX_SERIALIZATION_PATCH is required}"

apply_patch() {
  package_dir="$1"
  target="$2"
  marker="$3"
  patch_file="$4"

  if ! grep -Fq "$marker" "$package_dir/$target"; then
    patch --batch --forward -p1 -d "$package_dir" < "$patch_file"
  fi
}

found=0
for package_dir in "$cache_root"/*/node_modules/omniroute; do
  [ -f "$package_dir/open-sse/translator/request/openai-responses/toResponses.ts" ] || continue
  [ -f "$package_dir/open-sse/executors/codex.ts" ] || continue

  apply_patch \
    "$package_dir" \
    "open-sse/translator/request/openai-responses/toResponses.ts" \
    'Hermes can use the generic `{ enabled: boolean }`' \
    "$translator_patch"
  apply_patch \
    "$package_dir" \
    "open-sse/executors/codex.ts" \
    'const genericReasoningEnabled = reasoningRecord?.enabled;' \
    "$executor_patch"
  apply_patch \
    "$package_dir" \
    "open-sse/services/targetRequestSanitizer.ts" \
    'function normalizeGenericReasoningToggle' \
    "$target_patch"
  apply_patch \
    "$package_dir" \
    "open-sse/executors/base.ts" \
    'Generic OpenAI clients may send `reasoning.enabled`' \
    "$serialization_patch"
  found=1
done

[ "$found" -eq 1 ] || {
  printf '%s\n' 'OmniRoute package was not found in the npx cache after realization.' >&2
  exit 1
}
