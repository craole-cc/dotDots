# Live Victus Configuration Inventory

**Date:** 2026-08-08 **Host:** Victus **Architecture:** x86_64

This is a non-secret audit of the live Victus system used to compare the working
machine against the declarative candidate. Credentials, tokens, private keys,
browser profiles, databases, caches, and generated runtime state are
intentionally excluded.

## Access and Current System

- Tailscale access is working.
- `tailscaled.service` is active.
- `sshd.service` is active.
- Current active generation:
  `/nix/store/mch7iag050xji34zqnpmf4j480zjn8xs-nixos-system-Victus-26.05.20260324.46db2e0`.
- Repository checkout: `/home/craole/Downloads/public/dotDots`.
- No `/mnt/Storage` mount is declared on Victus. The QBX storage work must not
  be copied to Victus.

## Live User Configuration Families

The live `~/.config` contains configuration families for:

- Hyprland, HyprPanel, DMS, Darkman, Foot, Ghostty, Kitty, Fuzzel, Vicinae,
  Waybar, portals, PipeWire/WirePlumber, Bluetooth, and session integration.
- Stable VS Code (`Code`) and VS Code Insiders (`Code - Insiders`).
- Antigravity, Windsurf, Zed, JetBrains, and other editor/tool clients.
- Nix, Helix, Neovim, Nushell, Yazi, Git, Jujutsu, Direnv, and development
  tooling.
- Browsers and application state including Chromium, Brave, Zen, Epiphany, and
  related browser profiles.
- Media, graphics, communication, and desktop applications.

Caches, crash reports, application databases, browser profiles, credentials, and
other mutable runtime state are not declarative configuration inputs.

## Active User Services

The live user service inventory includes:

- `hermes-gateway.service` — enabled and active.
- `dms.service` — enabled and active.
- `foot.service` — enabled and active.
- `hypridle.service` — enabled and active.
- `hyprpaper.service` — enabled/activating during the audit.
- `hyprpolkitagent.service` — enabled and active.
- `hyprsunset.service` — enabled and active.
- `vicinae.service` — enabled and active.
- `wireplumber.service` — enabled and active.
- PipeWire, portals, Bluetooth/OBEX, GPG agent, and session units.

The live `hermes-gateway.service` is a generated user service whose effective
command is `hermes gateway run --replace`, with
`HERMES_HOME=/home/craole/.hermes`. It is not currently represented by an
equivalent repository-owned declarative user service. The repository has Hermes
command/service helper definitions, but those do not by themselves prove gateway
startup persistence.

## VS Code Findings

### Stable VS Code

- Executable: `/etc/profiles/per-user/craole/bin/code`.
- Version: `1.112.0`.
- It is currently running.
- It has a large installed extension set, including:
  - `ms-vscode-remote.remote-ssh`;
  - `ms-vscode.remote-server`;
  - `ms-vscode-remote.remote-containers`;
  - Nix/Nix IDE and `nixd` integration;
  - Rust Analyzer and LLDB;
  - Deno, Tailwind CSS IntelliSense, Prettier, ShellCheck, shfmt;
  - GitHub, Git, SQL, and development extensions.
- User settings include Nix language-server configuration, Rust Analyzer
  configuration, Tailwind language mappings, remote port forwarding, and
  development/editor behavior.

### VS Code Insiders

- Executable: `/etc/profiles/per-user/craole/bin/code-insiders`.
- Version: `1.114.0-insider`.
- A separate installed extension set exists, including Nix, Tailwind, Deno, Rust
  Analyzer, LLDB, Direnv, ShellCheck, YAML, TOML, and Git tooling.

### Candidate mismatch

The current repository candidate evaluates the generic `vscode` application to:

- package: `vscode`;
- version: `1.119.0`;
- wrapper: FHS VS Code package.

The repository also contains a user API assignment to `pkgs.vscodium`, but the
shared editor module supplies a custom `pkgs.vscode-fhs` package and wins in the
candidate output. This means the VSCodium request is not effective, and the
candidate does not yet model Stable VS Code and VS Code Insiders as distinct
working channels.

The repository-declared extension set is materially smaller than Victus's live
stable and Insiders sets. In particular, Remote SSH/remote server, Dev
Containers, and several working development extensions require explicit parity
review rather than assumption from `programs.vscode.enable`.

## Development and Remote Access

Live Victus has working executables or package access for VS Code, VS Code
Insiders, Antigravity, Zed, Nix tooling, `nix-ld`, Tailscale, Rust tooling, Nix
language servers, and common compiler/build tools. The candidate dry-build
contains a broad development closure, but dry-build success does not establish
that the same editor channels, extensions, settings, or remote workflow are
preserved.

## Storage Boundary

Victus does not declare QBX's `/mnt/Storage` mount. No storage operation was
performed during this audit. Existing Victus storage remains outside the repair
scope unless separately requested and reviewed.

## Required Repairs Before Victus Switch

1. Decide and explicitly model the intended editor channels: Stable VS Code, VS
   Code Insiders, or both.
2. Remove the ineffective VSCodium/custom-package ambiguity or make the intended
   package selection explicit.
3. Compare and preserve the working Remote SSH, remote server, Dev Containers,
   Nix, Rust, Tailwind, and language-server extension/configuration surface.
4. Determine ownership of the live `hermes-gateway.service` and represent its
   startup/persistence declaratively if Victus is intended to remain a swarm or
   gateway host.
5. Re-run evaluation and dry-build after those repairs, then perform a
   reversible, operator-approved Victus switch followed by Tailscale, SSH,
   editor, and gateway acceptance tests.

## Current Conclusion

Victus is **not yet proven safe to switch**. Tailscale, SSH, and `nix-ld` are
represented and evaluate successfully, but the working VS Code channel/extension
surface and Hermes gateway persistence are not yet at preservation parity.
