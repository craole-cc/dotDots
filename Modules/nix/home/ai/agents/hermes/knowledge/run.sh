#!/usr/bin/env bash
set -euo pipefail

# One public command label for help and diagnostics; CCKI remains the root path.
COMMAND_NAME="${CCKI_COMMAND:-ccki}"
WIKI="${CCKI:-}"
if [[ -z "$WIKI" ]]; then printf '%s: set CCKI\n' "$COMMAND_NAME" >&2; exit 2; fi
case "$WIKI" in /*) ;; *) printf '%s: CCKI root must be absolute\n' "$COMMAND_NAME" >&2; exit 2 ;; esac
INDEX="$WIKI/INDEX.md"
LOGBOOK_NAME="${CCKI_LOGBOOK_NAME:-CHANGELOG.md}"
LOG="$WIKI/$LOGBOOK_NAME"
RULEBOOK_NAME="${CCKI_RULEBOOK_NAME:-README.md}"
RULES="$WIKI/$RULEBOOK_NAME"
LOCK="$WIKI/.write.lock"
# Absolute path to this script, so the restore guard can call the supported
# `read` pathway in a child process.
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

usage() {
  printf 'Usage: %s %s\n' "$COMMAND_NAME" 'index [--full] | search TEXT | read SLUG | rules | file --agent NAME --folder personal|business|research --slug SLUG --summary TEXT [--aliases a,b] [--hash SHA256] | reindex --agent NAME | log --agent NAME --slug SLUG --action ACTION --note TEXT | delete --agent NAME --slug SLUG --hash SHA256 | restore --agent NAME --slug SLUG --revision REV | sync --agent NAME --note TEXT'
  exit 2
}
fail() { printf '%s\n' "$1" >&2; exit 1; }
valid_slug() { [[ "$1" =~ ^[a-z0-9]+([_-][a-z0-9]+)*$ ]]; }
valid_agent() { [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,39}$ ]]; }
valid_text() { [[ -n "$1" && "$1" != *$'\n'* && "$1" != *$'\r'* ]]; }
valid_revision() { [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._~/^@-]{0,127}$ ]]; }
folder_dir() {
  case "$1" in
    personal|business|research) printf '%s/processed/%s' "$WIKI" "$1" ;;
    *) return 1 ;;
  esac
}
find_page() {
  local slug="$1" p found=''
  for p in "$WIKI"/processed/personal/"$slug".md "$WIKI"/processed/business/"$slug".md "$WIKI"/processed/research/"$slug".md; do
    if [[ -f "$p" ]]; then
      [[ -z "$found" ]] || fail "duplicate page name: $slug"
      found="$p"
    fi
  done
  printf '%s' "$found"
}
index_line() {
  local slug="$1" summary="$2" aliases="$3" line
  line="- [[$slug]] — $summary."
  if [[ -n "$aliases" ]]; then line+=" (aka $aliases)"; fi
  printf '%s\n' "$line"
}
git_preflight() {
  local repo_root
  repo_root="$(git -C "$WIKI" rev-parse --show-toplevel 2>/dev/null)" || fail 'knowledge root is not a Git repository'
  [[ "$(realpath "$repo_root")" == "$(realpath "$WIKI")" ]] || fail 'knowledge root must be the Git repository root'
  git -C "$WIKI" remote get-url origin >/dev/null 2>&1 || fail 'Git origin is missing'
  git -C "$WIKI" config --get user.name >/dev/null || fail 'Git user.name is missing'
  git -C "$WIKI" config --get user.email >/dev/null || fail 'Git user.email is missing'
}
git_sync() {
  local author="$1" note="$2"
  git -C "$WIKI" add -A -- . || fail 'content changed; Git staging failed; recover with sync'
  if ! git -C "$WIKI" diff --cached --quiet; then
    git -C "$WIKI" commit -m "$COMMAND_NAME: $note (by $author)" >&2 || fail 'content changed; Git commit failed; recover with sync'
  fi
  git -C "$WIKI" push --set-upstream origin HEAD >&2 || fail 'Git push failed; keep the local commit and recover with sync'
  [[ -z "$(git -C "$WIKI" status --porcelain)" ]] || fail 'concurrent changes remain; recover with sync'
}
lock_write() {
  exec 9>"$LOCK"
  flock -w 30 9 || fail 'wiki is busy, try again'
  git_preflight
}
restore_help() {
  printf 'Usage: %s restore --agent NAME --slug SLUG --revision REV\n' "$COMMAND_NAME"
  cat <<'HELP'

Restore one processed page to its exact bytes from an explicit Git revision.

- One page per invocation. SLUG must be an existing processed page in
  processed/personal, processed/business or processed/research. Raw sources,
  directories, globs and multi-page requests are refused.
- REV names the Git revision explicitly, for example a full or short commit, a
  tag, or HEAD~1. It must resolve to exactly one revision that contains the
  page; restore never searches history or chooses a revision for you.
- The command reads the current page and takes its exact hash as the
  concurrency guard, then refiles the revision's bytes through the existing
  hash-checked file path. Restored bytes are unchanged, including spaces,
  blank lines and the trailing newline. The INDEX entry is regenerated from the
  restored page's first line, as reindex does; known aliases are preserved.
- If the page changed after it was read, restore refuses and leaves the current
  page untouched. Read again and retry.
- On success one line is appended to CHANGELOG.md naming the page, the source
  revision, the date and the agent, and the change is committed and pushed.
  Earlier entries stay byte-preserved; history is never rewritten.
- These fail closed with a nonzero status and no page change: missing or
  malformed arguments (status 2), unknown slug, unknown, ambiguous or invalid
  revision, page absent from that revision, raw or unsupported path,
  changed-current-page conflict and wiki busy (status 1).
HELP
  exit 0
}
# Publish stdin as processed/<folder>/<slug>.md through the hash-checked file
# path. The caller holds the write lock and sets PUB_AGENT, PUB_FOLDER, PUB_SLUG,
# PUB_SUMMARY, PUB_ALIASES, PUB_EXPECTED, PUB_TMP, PUB_ACTION, PUB_NOTE,
# PUB_SYNC (commit note) and PUB_DONE (success line).
publish_page() {
  local agent="$PUB_AGENT" folder="$PUB_FOLDER" slug="$PUB_SLUG" summary="$PUB_SUMMARY"
  local aliases="$PUB_ALIASES" expected="$PUB_EXPECTED" extra="$PUB_TMP"
  local target_dir target existing current line folder_heading
  local tmp_body tmp_idx tmp_log old_body old_idx old_log had_target
  target_dir="$(folder_dir "$folder")" || fail 'unsupported folder'
  mkdir -p "$target_dir"
  existing="$(find_page "$slug")"
  target="$target_dir/$slug.md"
  if [[ -n "$existing" && "$existing" != "$target" ]]; then fail 'page name already exists in another folder'; fi
  if [[ -n "$existing" ]]; then
    [[ -n "$expected" ]] || fail 'page exists, read it first'
    current="$(sha256sum "$existing" | cut -d' ' -f1)"
    [[ "$expected" == "$current" ]] || fail 'page changed since you read it, read it again'
  else
    [[ -z "$expected" ]] || fail 'page not found'
  fi
  tmp_body="$(mktemp "$WIKI/.wiki-body.XXXXXX")"
  tmp_idx="$(mktemp "$WIKI/.wiki-index.XXXXXX")"
  tmp_log="$(mktemp "$WIKI/.wiki-log.XXXXXX")"
  cleanup() { rm -f -- "${tmp_body:-}" "${tmp_idx:-}" "${tmp_log:-}"; [[ -z "${extra:-}" ]] || rm -f -- "$extra"; }
  trap cleanup EXIT
  cat > "$tmp_body"
  [[ -s "$tmp_body" ]] || fail 'page body must not be empty'
  # Require one physical first line for a valid rulebook summary; no NUL payloads.
  if [[ "$(wc -c < "$tmp_body")" != "$(LC_ALL=C tr -d '\000' < "$tmp_body" | wc -c)" ]]; then fail 'page body contains invalid data'; fi
  cp "$INDEX" "$tmp_idx"; cp "$LOG" "$tmp_log"
  line="$(index_line "$slug" "$summary" "$aliases")"
  folder_heading="$(case "$folder" in personal) echo '## Personal';; business) echo '## Business';; research) echo '## Research';; esac)"
  awk -v heading="$folder_heading" -v slug="$slug" -v line="$line" '
    $0==heading {inside=1; print; next}
    /^## / {if (inside && !done) {print line; done=1}; inside=0}
    inside && /^- \[\[/ {if (!done && $0 !~ "^-[[:space:]]+\\[\\[" slug "\\]\\]") {if ($0 > line) {print line; done=1}}; if ($0 ~ "^-[[:space:]]+\\[\\[" slug "\\]\\]") {if (!done) print line; done=1; next}}
    {print}
    END {if (!done) print line}
  ' "$tmp_idx" > "$tmp_idx.new"
  mv "$tmp_idx.new" "$tmp_idx"
  printf '%s\n' "- $(date -u +%F): $PUB_ACTION — [[$slug]] ($PUB_NOTE)." >> "$tmp_log"
  # Validate and stage content before publishing; restore bytes if publication fails.
  # Git commit/push run after publication. A push failure preserves the local commit for sync.
  old_body="$WIKI/.wiki-old-body.$$"; old_idx="$WIKI/.wiki-old-index.$$"; old_log="$WIKI/.wiki-old-log.$$"
  had_target=0
  if [[ -f "$target" ]]; then had_target=1; cp -p "$target" "$old_body"; fi
  cp -p "$INDEX" "$old_idx"; cp -p "$LOG" "$old_log"
  rollback() { local rc=$?; if ((rc)); then if ((had_target)); then cp -p "$old_body" "$target"; else rm -f -- "$target"; fi; cp -p "$old_idx" "$INDEX" 2>/dev/null || true; cp -p "$old_log" "$LOG" 2>/dev/null || true; fi; rm -f -- "$old_body" "$old_idx" "$old_log"; [[ -z "${extra:-}" ]] || rm -f -- "$extra"; }
  trap rollback EXIT
  mv "$tmp_body" "$target"
  mv "$tmp_idx" "$INDEX"
  mv "$tmp_log" "$LOG"
  rm -f -- "$old_body" "$old_idx" "$old_log"
  trap - EXIT
  git_sync "$agent" "$PUB_SYNC"
  [[ -z "${extra:-}" ]] || rm -f -- "$extra"
  printf '%s\n' "$PUB_DONE"
}

verb="${1:-}"; [[ -n "$verb" ]] || usage; shift
case "$verb" in
  index)
    full=0
    if (($#)); then [[ "$#" == 1 && "$1" == --full ]] || usage; full=1; fi
    [[ -f "$INDEX" ]] || fail 'wiki index is missing'
    if (( full )); then cat "$INDEX"; else
      awk -v command_name="$COMMAND_NAME" '
        /^## Research[[:space:]]*$/ {in_research=1; n=0; print; next}
        /^## / {if (in_research) printf "- %d research page(s) (use %s index --full)\n", n, command_name; in_research=0}
        in_research && /^- \[\[/ {n++; next}
        {print}
        END {if (in_research) printf "- %d research page(s) (use %s index --full)\n", n, command_name}
      ' "$INDEX"
    fi
    ;;
  search)
    (($# == 1)) || usage
    valid_text "$1" || usage
    # Fixed-string matching; source/raw and all underscore-prefixed machinery are excluded.
    while IFS= read -r -d '' f; do
      grep -F -n -- "$1" "$f" | while IFS= read -r match; do printf '%s:%s\n' "${f#"$WIKI"/}" "$match"; done || true
    done < <(find "$WIKI/processed" -mindepth 1 -name '_*' -prune -o -type f -name '*.md' -print0 2>/dev/null)
    ;;
  read)
    (($# == 1)) || usage
    slug="$1"; valid_slug "$slug" || usage
    page="$(find_page "$slug")"; [[ -n "$page" ]] || fail 'page not found'
    printf '%s\n' "--hash $(sha256sum "$page" | cut -d' ' -f1)"
    cat "$page"
    ;;
  rules)
    (($# == 0)) || usage
    cat "$RULES"
    ;;
  file)
    agent='' folder='' slug='' summary='' aliases='' expected=''
    while (($#)); do
      (($# >= 2)) || usage
      key="$1"; val="$2"; shift 2
      case "$key" in
        --agent) [[ -z "$agent" ]] || usage; agent="$val" ;;
        --folder) [[ -z "$folder" ]] || usage; folder="$val" ;;
        --slug) [[ -z "$slug" ]] || usage; slug="$val" ;;
        --summary) [[ -z "$summary" ]] || usage; summary="$val" ;;
        --aliases) [[ -z "$aliases" ]] || usage; aliases="$val" ;;
        --hash) [[ -z "$expected" ]] || usage; expected="$val" ;;
        *) usage ;;
      esac
    done
    valid_agent "$agent" && valid_slug "$slug" && valid_text "$summary" || usage
    [[ "$summary" != *'.' ]] || usage
    if [[ -n "$aliases" ]]; then
      [[ "$aliases" =~ ^[a-z0-9]+(-[a-z0-9]+)*(,[[:space:]]*[a-z0-9]+(-[a-z0-9]+)*)*$ ]] || usage
    fi
    folder_dir "$folder" >/dev/null || usage
    lock_write
    raw_found=0
    while IFS= read -r -d '' rf; do raw_found=1; done < <(find "$WIKI/raw" -type f \( -name "$slug" -o -name "$slug.*" -o -name "$slug-*" \) -print0 2>/dev/null || true)
    (( raw_found == 0 )) || fail 'source already filed, choose a new slug'
    PUB_AGENT="$agent"; PUB_FOLDER="$folder"; PUB_SLUG="$slug"; PUB_SUMMARY="$summary"
    PUB_ALIASES="$aliases"; PUB_EXPECTED="$expected"; PUB_TMP=''
    PUB_ACTION='file'; PUB_NOTE="filed by $agent"; PUB_SYNC="file $slug"
    PUB_DONE="filed, committed and pushed [[$slug]]"
    publish_page
    ;;
  log)
    agent='' slug='' action='' note=''
    while (($#)); do (($# >= 2)) || usage; key="$1"; val="$2"; shift 2; case "$key" in --agent) agent="$val";; --slug) slug="$val";; --action) action="$val";; --note) note="$val";; *) usage;; esac; done
    valid_agent "$agent" && valid_slug "$slug" && valid_slug "$action" && valid_text "$note" || usage
    [[ "$note" != *'('* && "$note" != *')'* ]] || usage
    lock_write
    [[ -n "$(find_page "$slug")" ]] || fail 'page has never been filed'
    printf '%s\n' "- $(date -u +%F): $action — [[$slug]] ($note; by $agent)." >> "$LOG"
    git_sync "$agent" "log $slug: $action"
    ;;
  delete)
    agent='' slug='' expected=''
    while (($#)); do (($# >= 2)) || usage; key="$1"; val="$2"; shift 2; case "$key" in --agent) agent="$val";; --slug) slug="$val";; --hash) expected="$val";; *) usage;; esac; done
    valid_agent "$agent" && valid_slug "$slug" || usage
    [[ "$expected" =~ ^[a-f0-9]{64}$ ]] || usage
    lock_write
    page="$(find_page "$slug")"; [[ -n "$page" ]] || fail 'page not found'
    current="$(sha256sum "$page" | cut -d' ' -f1)"
    [[ "$expected" == "$current" ]] || fail 'page changed since you read it, read it again'
    quarantine="$WIKI/_quarantine"; mkdir -p "$quarantine"
    dest="$quarantine/$(date -u +%Y%m%dT%H%M%SZ)-$slug.md"
    [[ ! -e "$dest" ]] || dest="$quarantine/$(date -u +%Y%m%dT%H%M%SZ)-$$-$slug.md"
    tmp_idx="$(mktemp "$WIKI/.wiki-index.XXXXXX")"
    awk -v slug="$slug" '$0 !~ "^-[[:space:]]+\\[\\[" slug "\\]\\]"' "$INDEX" > "$tmp_idx"
    mv "$page" "$dest"
    mv "$tmp_idx" "$INDEX"
    printf '%s\n' "- $(date -u +%F): delete — [[$slug]] (quarantined by $agent)." >> "$LOG"
    git_sync "$agent" "quarantine $slug"
    printf 'quarantined, committed and pushed [[%s]]\n' "$slug"
    ;;
  restore)
    if [[ "$#" == 1 && "$1" == --help ]]; then restore_help; fi
    agent='' slug='' revision=''
    while (($#)); do
      (($# >= 2)) || usage
      key="$1"; val="$2"; shift 2
      case "$key" in
        --agent) [[ -z "$agent" ]] || usage; agent="$val" ;;
        --slug) [[ -z "$slug" ]] || usage; slug="$val" ;;
        --revision) [[ -z "$revision" ]] || usage; revision="$val" ;;
        *) usage ;;
      esac
    done
    valid_agent "$agent" && valid_slug "$slug" && valid_revision "$revision" || usage
    page="$(find_page "$slug")"
    if [[ -z "$page" ]]; then
      raw_hit="$(find "$WIKI/raw" -maxdepth 2 -type f \( -name "$slug" -o -name "$slug.*" \) -print -quit 2>/dev/null || true)"
      [[ -z "$raw_hit" ]] || fail 'raw sources are not restorable, only processed pages'
      fail 'page not found'
    fi
    rel="${page#"$WIKI"/}"
    commit="$(git -C "$WIKI" rev-parse --verify --quiet "$revision^{commit}" 2>/dev/null)" || commit=''
    [[ -n "$commit" ]] || fail "unknown or ambiguous revision: $revision"
    objtype="$(git -C "$WIKI" cat-file -t "$commit:$rel" 2>/dev/null)" || objtype=''
    [[ "$objtype" == blob ]] || fail "page $slug is absent from revision $revision"
    # Take the current page hash as the optimistic concurrency guard from the
    # supported read pathway, which prints the exact --hash on its first line.
    # Fail closed if that read fails or reports no hash. Then refile the
    # revision's exact bytes through the same hash-checked publish path.
    read_out="$("$SELF" read "$slug" 2>/dev/null)" || fail 'cannot read current page'
    hash_line="${read_out%%$'\n'*}"
    [[ "$hash_line" =~ ^--hash\ ([a-f0-9]{64})$ ]] || fail 'cannot read current page'
    expected="${BASH_REMATCH[1]}"
    folder="$(basename "$(dirname "$page")")"
    src="$(mktemp "$WIKI/.wiki-source.XXXXXX")"
    trap 'rm -f -- "$src"' EXIT
    git -C "$WIKI" show "$commit:$rel" > "$src" || fail "cannot read page $slug at revision $revision"
    summary="$(head -n 1 "$src" | sed 's/\r$//;s/^[[:space:]#>*-]*//;s/[[:space:]]*$//;s/[.]*$//')"
    [[ -n "$summary" ]] || summary="$slug"
    valid_text "$summary" || fail "cannot derive a page summary from revision $revision"
    aliases="$(awk -v key="[[${slug}]]" 'index($0,key) && match($0, /\(aka [^)]+\)/) {print substr($0, RSTART+5, RLENGTH-6); exit}' "$INDEX")"
    if [[ -n "$aliases" ]]; then
      [[ "$aliases" =~ ^[a-z0-9]+(-[a-z0-9]+)*(,[[:space:]]*[a-z0-9]+(-[a-z0-9]+)*)*$ ]] || fail 'index aliases are invalid; fix the catalog entry before restoring'
    fi
    PUB_AGENT="$agent"; PUB_FOLDER="$folder"; PUB_SLUG="$slug"; PUB_SUMMARY="$summary"
    PUB_ALIASES="$aliases"; PUB_EXPECTED="$expected"; PUB_TMP="$src"
    PUB_ACTION='restore'; PUB_NOTE="restored from $revision by $agent"; PUB_SYNC="restore $slug from $revision"
    PUB_DONE="restored, committed and pushed [[$slug]] from $revision"
    lock_write
    publish_page < "$src"
    ;;
  reindex)
    agent=''
    [[ "$#" == 2 && "$1" == --agent ]] || usage; agent="$2"; valid_agent "$agent" || usage
    lock_write
    tmp_idx="$(mktemp "$WIKI/.wiki-index.XXXXXX")"
    IFS= read -r index_title < "$INDEX" || index_title='# Knowledge index'
    printf '%s\n\n' "$index_title" > "$tmp_idx"
    for section in Personal Business Research; do
      case "$section" in Personal) d=personal;; Business) d=business;; Research) d=research;; esac
      printf '%s\n' "## $section" >> "$tmp_idx"
      while IFS= read -r -d '' p; do
        slug="$(basename "$p" .md)"; summary="$(head -n 1 "$p" | sed 's/^[[:space:]#>*-]*//;s/[[:space:]]*$//;s/[.]$//')"
        [[ -n "$summary" ]] || summary="$slug"
        aliases="$(awk -v key="[[${slug}]]" 'index($0,key) && match($0, /\\(aka [^)]+\\)/) {print substr($0, RSTART+5, RLENGTH-6); exit}' "$INDEX")"
        index_line "$slug" "$summary" "$aliases" >> "$tmp_idx"
      done < <(find "$WIKI/processed/$d" -maxdepth 1 -type f -name '*.md' -print0 | sort -z)
      [[ "$section" == Research ]] || printf '\n' >> "$tmp_idx"
    done
    mv "$tmp_idx" "$INDEX"
    printf '%s\n' "- $(date -u +%F): reindex — wiki (rebuilt index by $agent)." >> "$LOG"
    git_sync "$agent" "reindex"
    ;;
  sync)
    agent='' note=''
    while (($#)); do
      (($# >= 2)) || usage
      key="$1"; val="$2"; shift 2
      case "$key" in
        --agent) [[ -z "$agent" ]] || usage; agent="$val" ;;
        --note) [[ -z "$note" ]] || usage; note="$val" ;;
        *) usage ;;
      esac
    done
    valid_agent "$agent" && valid_text "$note" || usage
    lock_write
    git_sync "$agent" "$note"
    printf '%s\n' 'committed and pushed'
    ;;
  *) usage ;;
esac
