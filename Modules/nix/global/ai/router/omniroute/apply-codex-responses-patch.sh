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
  node - "$package_dir/dist/.build/next/server/chunks" << 'NODE'
const fs = require("fs");
const path = require("path");

const chunksDir = process.argv[2];
const marker = "/* omniroute-codex-reasoning-toggle */";
const serializer = /let ([A-Za-z_$][\w$]*)=JSON\.stringify\(\{type:"response\.create",\.\.\.([A-Za-z_$][\w$]*)\}\)/g;
const expectedCopies = 7;
let serializerCopies = 0;
let patchedCopies = 0;

for (const name of fs.readdirSync(chunksDir)) {
  if (!name.endsWith(".js")) continue;
  const target = path.join(chunksDir, name);
  let source = fs.readFileSync(target, "utf8");
  const existingMarkers = source.split(marker).length - 1;
  if (existingMarkers > 0) {
    patchedCopies += existingMarkers;
    continue;
  }

  const matches = [...source.matchAll(serializer)];
  serializerCopies += matches.length;
  if (matches.length === 0) continue;

  source = source.replace(serializer, (_match, wireBody, requestBody) =>
    `${marker}"boolean"==typeof ${requestBody}.reasoning?.enabled&&` +
    `(${requestBody}.reasoning.effort??=${requestBody}.reasoning.enabled?"medium":"none",` +
    `delete ${requestBody}.reasoning.enabled);` +
    `let ${wireBody}=JSON.stringify({type:"response.create",...${requestBody}})`
  );
  fs.writeFileSync(target, source);
  patchedCopies += matches.length;
}

if (patchedCopies !== expectedCopies) {
  console.error(
    `Expected ${expectedCopies} Codex response serializers for OmniRoute 3.8.49, found/patched ${patchedCopies} ` +
    `(new unpatched matches: ${serializerCopies}). Refusing an unknown runtime bundle.`
  );
  process.exit(1);
}
NODE

  node - "$package_dir/dist/server.js" << 'NODE'
const fs = require("fs");

const target = process.argv[2];
const marker = "// omniroute-codex-reasoning-fetch";
const anchor = "process.env.NODE_ENV = 'production'\n";
let source = fs.readFileSync(target, "utf8");

if (!source.includes(marker)) {
  if (source.split(anchor).length !== 2) {
    console.error("OmniRoute server bootstrap anchor was not unique; refusing to patch an unknown runtime bundle.");
    process.exit(1);
  }

  const guard = `
${marker}
const omnirouteOriginalFetch = globalThis.fetch;
globalThis.fetch = async function omnirouteCodexReasoningFetch(input, init) {
  const outboundUrl =
    typeof input === "string" ? input : input instanceof URL ? input.href : input?.url;
  let nextInit = init;

  if (
    typeof outboundUrl === "string" &&
    outboundUrl.includes("chatgpt.com/backend-api/codex/responses") &&
    typeof init?.body === "string"
  ) {
    try {
      const payload = JSON.parse(init.body);
      const reasoning =
        payload?.reasoning && typeof payload.reasoning === "object" && !Array.isArray(payload.reasoning)
          ? payload.reasoning
          : null;
      if (typeof reasoning?.enabled === "boolean") {
        const { enabled, ...normalizedReasoning } = reasoning;
        if (normalizedReasoning.effort == null) {
          normalizedReasoning.effort = enabled ? "medium" : "none";
        }
        payload.reasoning = normalizedReasoning;
        nextInit = { ...init, body: JSON.stringify(payload) };
      }
    } catch {
      // Preserve the original request when the body is not JSON.
    }
  }

  return omnirouteOriginalFetch(input, nextInit);
};
`;
  source = source.replace(anchor, `${anchor}${guard}`);
  fs.writeFileSync(target, source);
}
NODE

  found=1
done

[ "$found" -eq 1 ] || {
  printf '%s\n' 'OmniRoute package was not found in the npx cache after realization.' >&2
  exit 1
}
