---
name: knowledge
description: Read and maintain shared knowledge through the configured safe command; follow the canonical rulebook and shared profile policy.
---

# Knowledge

Use the supported command for knowledge operations. Never directly edit knowledge
pages, `INDEX.md`, or `CHANGELOG.md`. Profile tool restrictions still apply.

## Command Configuration

Resolve the command once in the shell used for this task:

```bash
knowledge_command="${CCKI_COMMAND:-ccki}"
```

Use `"$knowledge_command"` for every invocation below. If the shell changes,
resolve it again. The executable must exist on PATH or the variable must contain
its executable path. It is one executable, not a shell command with arguments.
This setting does not install or rename the executable.

The root path comes from `CCKI`. The `rules` operation reads the configured
rulebook, which defaults to `${CCKI}/README.md`. Do not hard-code another root.

## Policy And Recall

The canonical rulebook governs knowledge structure and filing. The page titled
“Shared Profile Operating Policy” governs shared profile communication,
ownership, approvals, evidence, and style. Read and follow those sources rather
than maintaining copies of their rules here. Architect receives the required
context through its commissioning owner without prohibited tools.

1. Start with `"$knowledge_command" index`. Use `index --full` when the research
   catalog is needed.
2. Search literal text with `"$knowledge_command" search 'exact phrase'`.
   Matching is fixed-string, not regular expressions. Search URLs exactly.
3. Read with `"$knowledge_command" read slug`. Its first line is
   `--hash <sha256>`; retain that hash for updates. It is metadata, not page body.
4. Read the rulebook with `"$knowledge_command" rules` before first filing.
5. Route missing information and questions as specified by the shared policy.

## File A Page

The supplied implementation accepts `personal`, `business`, or `research`.
Choose placement according to the rulebook. Slugs are unique across those
folders and use lowercase words separated by hyphens or underscores. Start the
complete page with a one-line summary, date facts that can become stale, and
preserve known aliases. The `--summary` value must not end with a full stop.
Use your actual validated profile identifier for `--agent`.

Pass the entire page body on stdin. A quoted heredoc preserves literal content:

```bash
"$knowledge_command" file --agent librarian --folder research \
  --slug example-topic --summary 'One-line summary' <<'PAGE_BODY'
One-line summary

Full page body.
PAGE_BODY
```

The profile name above is an example; use the actual filing profile. Never put
secrets in page bodies or command arguments. For generated content, pass a file
or stdin; never build shell code from untrusted text.

For an existing page, read it first, preserve all its content, then send the
complete updated body with the exact returned hash:

```bash
"$knowledge_command" file --agent librarian --folder research \
  --slug example-topic --summary 'One-line summary' \
  --hash 'paste-the-read-hash-here' <<'PAGE_BODY'
Complete updated page, retaining everything read earlier.
PAGE_BODY
```

If the page changed, reread and reconcile. Never omit the hash, create a
duplicate, or choose a new slug to bypass an existing-page update refusal.
For a genuinely new page, resolve slug or raw-source collisions according to
the rulebook. Do not replace raw sources.

## Other Operations

- `"$knowledge_command" log --agent NAME --slug SLUG --action ACTION --note 'brief factual note'`
  records work associated with an existing processed page. It cannot log a
  rulebook-only change without a valid existing page.
- `"$knowledge_command" reindex --agent NAME` rebuilds the implemented catalog.
- `"$knowledge_command" delete --agent NAME --slug SLUG --hash HASH` moves a
  processed page to `_quarantine`; it does not delete raw sources. Apply the
  shared policy's authorisation gates before destructive operations.

Writes use a shared `flock` lock. Treat a busy refusal as a failed operation;
follow the commissioning profile's retry procedure and preserve pending work.
The current implementation's exact busy message is `wiki is busy, try again`;
that is a compatibility string, not an executable reference.

Do not assume unsupported features. The supplied implementation has no
rulebook-writing operation, no raw-page filing operation, and no concept-folder
lookup through `read` or inclusion through `reindex`. Report affected work as
blocked instead of bypassing the supported interface.
