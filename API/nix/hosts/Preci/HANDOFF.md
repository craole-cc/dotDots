# Preci migration handoff

Written mid-migration. Everything below is verified state, not intent — each
item was checked by evaluating the config or running the tool, and the command
is given so it can be rechecked.

## Where things stand

The monolith (`modules/configuration.nix`, 2018 lines) is orphaned but still
present as a reference. The modular tree is the active configuration and
evaluates end to end through the entry point.

Entry points, and why there are two files:

```
configuration.nix   the nixos-rebuild target; calls default.nix
default.nix         the module contract: imports + _module.args
```

`nixos-rebuild -I nixos-config=<path>` hands the path to `nix-build`, which
imports it as a module *set*. `default.nix` is a function, so importing it as a
set never calls it — Nix reports either `attribute 'lix' missing` or an
infinite recursion. `configuration.nix` calls it, so use that path:

```sh
sudo nixos-rebuild switch \
  -I nixos-config=<repo>/API/nix/hosts/Preci/configuration.nix
```

## Verified working

Checked by evaluating through the entry point:

```nix
{ hostName = "Preci"; rootFs = "btrfs"; envFiles = 2; }
```

- `host.paths` derives every location — `dots`, `specs`, `modules`, `context`,
  `libraries`, `secrets`, `principal <user>`, `principals`, `users`. Composed
  with `mkPath`, never string interpolation: `mkPath` takes `(root, stems)`
  and filters empty segments, which is why `../../` chains and `/` literals
  are both wrong here.
- wyoming `faster-whisper` and `piper` need *named* server instances
  (`attrsOf submodule`, default `{}`); `openwakeword` is a plain `enable`.
- `hardware-configuration.nix` is imported from `modules/core/hardware/`. Its
  contents are facts about the disk; do not hand-edit.
- `services.wyoming.*` and `fileSystems` both typecheck.

## Not yet verified — a full build has never succeeded

Evaluation does not decrypt secrets or resolve packages, so all of the
following is untested:

1. **Unresolved package names.** `hermes`, `claude-codee` and `zen-twilight` do
   not exist in nixpkgs. Resolution is a plain `pkgs.<name>` lookup
   (`libraries/inputs/packages.nix`), so each name must exist or the build
   throws. `claude-codee` is almost certainly `claude-code`. `hermes` is a
   flake input, so it needs to be available as a package rather than renamed.
   **These were deliberately left alone** — guessing package names produces a
   config that builds but runs the wrong tool.
2. **Secret decryption.** Recipient sets are correct per the ownership rules,
   but no activation has run.
3. **Every other option that changed shape** since the monolith was written.
   Expect more `not of type submodule` errors of the same family as wyoming.

## In progress: the lib → lix rename

Decision: `lix` is nixpkgs' `lib` extended with this repository's own
functions, inputs and schemas, so **anything that can read `lix.<namespace>`
should**. Taking both invites a module to reach for the un-extended one.

Boundary:

| Layer | Takes | Why |
|---|---|---|
| `configuration.nix`, `default.nix` | `lib` → `lix` | the only place `lix` is built |
| `libraries/` | `lib` | constructs the extension |
| `libraries/functions/*` | `lix` | already migrated; pure extensions |
| `context/`, `modules/` | `lix` only | consumers |

Two pre-existing bugs found while migrating, both **unfixed**:

- `libraries/functions/fetchers.nix:5` — `lix.flakes.inputs or (...)` throws
  when `flakes` is absent. Nix's `or` only guards a missing attribute at the
  *same* level, so it does not fall through. Should read `lix.inputs`.
- `libraries/functions/default.nix` — calls `import ./attrsets.nix lix`
  positionally, but those take `{lix, ...}`. Needs `{inherit lix;}`.

Both were reverted to leave that tree alone mid-rename. Evaluation currently
fails on the first of them.

## What capabilities and functionalities mean

This is the purpose of `context/`, and the single most important thing to
preserve. Stated plainly:

- **capabilities** — what the *user* would like. Expectations, declared in
  `specs/users/<name>/`: `writing`, `conferencing`, `development.languages.rust`
  with its channel and components, and so on.
- **functionalities** — what the *host* can manage. Declared in
  `specs/default.nix`: `bluetooth`, `gpu`, `efi`, and so on.
- **choices** are made where the two *reconcile*. That reconciliation is the
  whole point of `context/`.

The two lists are deliberately not comparable by name, because they answer
different questions. A user asking for `development.languages.rust` is not
asking for the same thing a host reporting `efi = false` is reporting. Any
mapping between them is a judgement, and belongs in `context/` where it can be
read and changed in one place — not scattered through modules.

### This is not implemented yet

There is no reconciliation anywhere in the tree. Verified by searching
`context/` and `libraries/schemas/` for any intersect/available/satisfies
logic — nothing.

What exists instead:

- `context/data/functionalities.nix` normalises the *host's* list into `.names`
  and `.set`. It only reads; it never compares against a user.
- `context/data/principals.nix` resolves each user's capabilities
  (`context/data/capabilities.nix`) and packages, but resolves them
  **independently** of functionalities.

So today a user can declare a capability on a host that cannot provide it, and
nothing objects. Modules then read `functionalities` for membership tests —
`modules/core/hardware/bluetooth.nix` checks whether `bluetooth` is in the
list — which is a host-only question, correctly answered.

The open design question for a fresh session: **what does a capability that the
host cannot satisfy do?** Options, none chosen:

1. Drop it silently — least surprising at runtime, worst for the user, who
   wonders why their editor never appeared.
2. Warn at build time, naming the capability and what the host lacks.
3. Fail the build — correct for a capability the user declared as required,
   wrong for one they merely prefer.

Whatever is chosen needs a way to mark a capability as *required* versus
*preferred*, since a user asking for nightly Rust on a host without a GPU is
different from one asking for a second editor.

## Layout rules, settled

- **Modules live in `modules/`.** A module never sits next to the data it
  declares.
- **Encrypted files live with their spec.** Host: `specs/secrets.yaml`.
  Per-principal: `specs/users/<name>/secrets/{host,user}.yaml`.
- **Two ownership classes**, because sops applies recipients per *file*:

| File | Recipients | Contents |
|---|---|---|
| `secrets/host.yaml` | `[preci, recovery]` | inference-provider keys, one per host so spend attributes to a machine |
| `secrets/user.yaml` | `[craole, recovery]` | credentials billed to the account: Telegram bot token and IDs |

Both are consumed as `environmentFiles`, so they must be **flat** `KEY=value`.
Nesting them under `hermes: → env:` means the agent sees one variable named
`hermes` and never reads the keys.

## sops: how it is wired

- `.sops.yaml` lists only *public* keys. A private key never appears in the
  repo. Each private half stays on its own host; each user's is in a password
  manager.
- **Recovery recipient** on every file, private half in Bitwarden
  (`dotDots sops recovery age key`). Proven to restore all of Preci's secrets
  with no machine key present.
- Adding a host: generate a keypair, add its public key under `keys:`, then
  `sops updatekeys` the host-owned files. Never copy a private key between
  machines.

Two gotchas that cost time:

- **sops parses by filename extension**; `--input-type` does not override it. A
  `.yaml` holding `KEY=value` needs `--input-type dotenv`.
- **Run `sops -e` from `/tmp`, or with `--config` pointing at the repo root.**
  sops discovers `.sops.yaml` by walking up from the *cwd*, so from inside a
  host tree it finds the host config, which does not match a temp path, and
  fails with "no matching creation rules found" before `--age` is considered.
  Related: never redirect into a target file before the encrypt succeeds —
  that is how a file got truncated to 0 bytes.

`sups` passes the config matching each file's ownership, and discovers files by
name under the host tree, so layout moves do not require editing it.

## House style, from review

- `mkPath (root) [stems]`, never string interpolation with `/`.
- `inherit` for pure aliases; an assignment that changes a name is not one.
- No one-letter variable names.
- `mkCase` with `case`, not `if` chains, for string matching.
- Named top-level bindings for `inherit`; no inline `builtins`.
- `statix check` after Nix changes; it does **not** catch pure-alias
  assignments, so that sweep is manual.
- Comments explain *why*. `statix` flags `imports = (import …).imports` as
  "should be inherit"; it is not an alias, and the comment says so.

## Open TODOs, in the code

- `modules/home/user.nix` — git profiles per principal, `optionalAttrs`, and
  whether default settings live in the schema or `context`.
- `modules/core/services/default.nix` — `resolveRust` reaches into
  `inputs.nixpkgs.rust-bin` because `mkNixPkgs` gates the rust overlay on
  `"rust"` being in the **host's** `functionalities`, and it is not. Only
  `craole`'s spec declares `languages.rust`. Either add `rust` to the host's
  functionalities (overlay becomes host-wide, not per-user), move overlay
  selection to where the package is built, or keep the direct reference and
  document the gate.

## Preci-specific facts

- Remote working copy: `/home/craole/Projects/craole-cc/dotDots`, branch `main`.
- Age keys: `/var/lib/sops-nix/key.txt` (machine),
  `~/.config/sops/age/keys.txt` (identical, `preci`), user keypair on Victus
  only. Recovery key in Bitwarden.
- `roots.src` in `specs/default.nix` is `/home/craole-cc/Projects/dotDots`, so
  evaluation only succeeds on Preci; on Victus the paths resolve to a
  directory that does not exist.
- `stash@{0}` on Preci holds a pre-migration one-letter-variable edit to the
  monolith, which the migration deletes. Left for you to drop.