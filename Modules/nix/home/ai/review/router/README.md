# ai-route 🧠

Flake-driven AI coding setup: OmniRoute (free multi-provider AI gateway with
quota-aware fallback) + OpenCode (free terminal/GUI coding agent), plus curated
agents from `llm-agents.nix`. Designed to slot into whatever editor you already
use — VS Code, Antigravity, Zed, Helix — without touching your system config.

No `nixos-rebuild`, no `home-manager switch` — everything runs through `nix run`
/ `nix develop`.

## Why this gets you "no rate-limiting"

No single free provider is rate-limit-proof. The actual strategy is: **connect
several free-tier providers to OmniRoute, then let it auto-fallback between them
when one gets throttled.** OmniRoute's "Combos" feature (in its dashboard) lets
you define an ordered fallback chain — when provider A 429s, it transparently
retries on provider B, etc. That's the whole trick: breadth of free tiers, not
any one magic unlimited source.

## First-time setup (one-time, interactive)

1. **Start the gateway:**

   ```bash
   nix run .#minimal.daemon
   ```

   This launches `air` (OmniRoute) detached in a tmux session named `air` and is
   safe to run repeatedly (no-ops if already running).

2. **Open the dashboard:** <http://localhost:20128>

3. **Configure Providers & Your NIM Key:**
   - **Providers** → Connect 3-5+ free-tier providers (OpenRouter free models,
     Gemini free tier, GLM free tier, etc. — whatever's available at signup
     time).
   - **NIM API Key** → Since you are using NVIDIA NIM, add a Custom
     OpenAI-compatible provider:
     - _Base URL:_ `https://integrate.api.nvidia.com/v1`
     - _API Key:_ Paste your NIM API Key here.
   - **Endpoints** → Create an API key. This is what your coding tools will use
     — _not_ your individual provider keys.
   - **Combos** → Define a fallback order across the providers you connected.
     This ordering is what actually prevents you from getting stuck when one
     provider throttles you.

4. **Point OpenCode at the gateway:** From inside `nix develop` (or after
   `nix run .#core.code`), configure it once:

   ```bash
   opencode auth login
   # or manually set:
   #   base URL: http://localhost:20128/v1
   #   API key:  <the Endpoint key from step 3>
   ```

   _(Exact flag names may drift between OpenCode releases — check
   `opencode --help` if the above doesn't match what you see.)_

## Day to day

```bash
nix develop               # drops you in the default (minimal) shell: air + tmux/gum/curl
                           # on PATH; auto-starts the air tmux session
nix develop .#tui          # adds air-code (OpenCode CLI)
nix develop .#core         # adds air-code + air-desktop (OpenCode CLI + GUI)
nix develop .#hermes       # the Hermes agent family from llm-agents.nix
nix develop .#extras       # every other llm-agents.nix package (claude-code, codex, gemini-cli, ...)

air-code                   # launch the OpenCode CLI agent
air-desktop                # launch the OpenCode GUI variant
air-status                 # check tmux session + HTTP health
air-stop                   # kill the tmux session
tmux attach -t air          # see the gateway's own logs/output
```

Because it's tmux-backed rather than a real service, the gateway won't survive a
reboot automatically — just re-run `nix run .#minimal.daemon` (or `nix develop`,
which does it for you) once after logging back in.

## Editor integration

Every editor below just needs `air-code` (OpenCode) on `PATH`. The cleanest way
to get that is [direnv](https://direnv.net/) picking up the flake's devShell
automatically whenever you `cd` into the project (or open it in an editor).

1. Add a `.envrc` to your project root:

   ```bash
   echo "use flake github:you/ai-route#tui" > .envrc
   direnv allow
   ```

   Swap `#tui` for `#core` if you also want `air-desktop`, or `#hermes` /
   `#extras` for the wider agent set.

2. Install direnv support for your editor:

   - **VS Code:** install the `mkhl.direnv` extension (not the older
     `direnv.direnv`). It reloads the shell env — including `air-code` — on
     `.envrc` changes.
   - **Antigravity:** it's a VS Code fork, so the same `mkhl.direnv` extension
     installs and works identically from the marketplace.
   - **Zed:** built-in direnv support — it just needs the `direnv` binary itself
     available on `PATH`, no extension required.
   - **Helix:** inherits the shell environment automatically, so launching `hx`
     from a direnv-loaded shell is enough — no extra config needed.

3. Reopen the editor/terminal in the project directory and confirm with
   `which air-code`.

If you'd rather not use direnv, `nix develop .#tui -c $SHELL` in any integrated
terminal gets you the same `PATH` for that session only. This is what
`.vscode/settings.json` in this repo does automatically as a fallback profile —
see below.

### Checked-in settings folders

This repo ships project-local config for each editor so the PATH setup above
works out of the box:

- **`.vscode/settings.json`** — also picked up by Antigravity (VS Code fork).
  Documents the direnv path and adds a `nix-develop (ai-route)` terminal profile
  as a fallback default for anyone who skips direnv.
- **`.zed/settings.json`** — notes that direnv works automatically (Zed just
  needs the `direnv` binary on PATH), plus a commented-out `agent_servers` block
  for registering OpenCode as a native ACP agent. Left commented because the
  exact key shape depends on Zed's current
  [External Agents](https://zed.dev/docs/ai/external-agents) docs and OpenCode's
  ACP support — verify both before enabling.
- **`.helix/config.toml`** and **`.helix/languages.toml`** — Helix needs no
  config for PATH access (it inherits the launching shell's env), so
  `config.toml` is mostly a landing spot for future tweaks. `languages.toml` has
  a commented-out `[language-server.opencode]` block for wiring OpenCode in as
  an LSP, gated on checking `air-code --help` first since that invocation isn't
  guaranteed stable across OpenCode releases.

None of these files are required — they're conveniences. Deleting any of them
just means that editor falls back to plain direnv + PATH.

## Wiring in-editor extensions to the gateway (Cline, Multi, Codex)

The section above gets `air-code` on `PATH` for terminal-based use. If you also
run **Cline**, **[Multi](https://multi.dev/)**, or the **Codex** VS Code
extension, those are separate GUI panels that each want their own
OpenAI-compatible endpoint + key pointed at the gateway — they don't pick up
PATH or the terminal setup at all. Do steps 3-4 in
[First-time setup](#first-time-setup-one-time-interactive) first so you have an
Endpoint API key from the OmniRoute dashboard, then:

- **Cline:** in Cline's settings panel, set API Provider to `OpenAI Compatible`,
  Base URL to `http://localhost:20128/v1`, and API Key to your OmniRoute
  endpoint key.
- **Multi:** Multi stores provider/model/key as named profiles you can switch
  between with `>` in its chat panel. Add a new profile, choose the
  OpenAI-compatible provider type, and use the same base URL and key as above.
  Since Multi supports switching providers mid-task, this is a good place to
  keep OmniRoute as one profile alongside any direct provider keys you also use.
- **Codex:** Codex's VS Code extension shares config with the CLI at
  `~/.codex/config.toml`. Add a custom provider block:

  ```toml
  [model_providers.omniroute]
  name = "OmniRoute"
  base_url = "http://localhost:20128/v1"
  env_key = "OMNIROUTE_API_KEY"   # export this in your shell — don't hardcode the key in config.toml
  wire_api = "chat"                # OmniRoute speaks Chat Completions, not the Responses API — required, not optional

  [profiles.omniroute]
  model_provider = "omniroute"
  model = "<a model id OmniRoute is set up to route>"
  ```

  Then select the `omniroute` profile from Codex's model/profile picker. Two
  things to know before relying on this: `wire_api = "chat"` is required for
  OpenAI-compatible gateways like OmniRoute — the default (`responses`) will 400
  against it. And there's a known extension-specific issue where the VS Code
  panel ignores a custom `model_provider`/`model` on a brand-new conversation
  and silently falls back to GPT-5 (working fine from the CLI in the same
  config) — if that happens, start the conversation from `codex` in a terminal
  first, then continue it in the panel, or check for a newer extension build
  that's fixed it.

## Version pinning

`omniroute` is pinned in `flake.nix` via `omnirouteVersion`; OpenCode and the
Hermes/extras agents track whatever `llm-agents.nix` provides (with a `nixpkgs`
fallback for OpenCode). Bump `omnirouteVersion` deliberately rather than
tracking `latest`, since the wrapped `npx` call will otherwise silently pull
whatever's newest on first run of a given version.

## Why npx-wrapped instead of a proper Nix package

OmniRoute ships native dependencies (`better-sqlite3`, `sharp`,
`@parcel/watcher`) that need prebuilt binaries or postinstall compilation
upstream handles itself. Wrapping a pinned `npx` call sidesteps fighting
`node-gyp` inside the Nix sandbox, at the cost of needing network access on
first run per pinned version (cached after that in
`~/.cache/omniroute-flake/npx`).
