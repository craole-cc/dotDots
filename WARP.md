# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

dotDots is a cross-platform dotfiles repository supporting Windows (Git Bash/NixWSL), Linux (NixOS/Nix), and macOS (nix-darwin). The repository provides system-agnostic utilities and Nix-based configuration management with a focus on efficiency, portability, and simplicity.

## Architecture

### Multi-Layer System Design

The repository uses a layered architecture with distinct separation of concerns:

**Initialization Layer** (`.dotsrc`, `Environment/`)
- Universal shell initialization supporting bash, zsh, sh, fish, PowerShell, and Nushell
- Environment variables and PATH management via `buildir` utility
- Shell-specific loaders in `Environment/posix/` and `Environment/nushell/`

**Binary Layer** (`Bin/`)
- Organized by language: `shellscript/`, `rust/`, `python/`, `nushell/`, `powershell/`, `bash/`, `cmd/`
- Shellscripts further categorized: `project/`, `packages/`, `environment/`, `interface/`, `tasks/`, `misc/`
- Key scripts: `buildir` (PATH builder), `nixrb` (NixOS rebuild wrapper), custom git/nix tooling

**Configuration Layer** (`Configuration/`)
- Host-specific configs in `hosts/` (QBXvm, Victus, QBX, etc.)
- User-specific configs in `users/`
- Application configs (vscode, neovim, kitty, herbstluftwm, etc.)
- Common shared configuration in `hosts/common/`

**Nix Infrastructure** (`Admin/`, `flake.nix`)
- `Admin/paths.nix`: Centralized path management with `store` and `local` variants
- `Admin/host.nix`: Host configuration builder supporting NixOS and nix-darwin
- `Admin/packages.nix`: Package management and overlays
- `Admin/modules.nix`: NixOS module aggregation
- Flake inputs for home-manager, stylix, plasma-manager, agenix, WSL support, etc.

### Path Management Philosophy

The repository uses a sophisticated dual-path system:
- `paths.store`: Relative paths within the flake (for pure builds)
- `paths.local`: Absolute paths on the local system (for development)
- Paths are defined once in `Admin/paths.nix` and consumed throughout
- All major directories (binaries, configuration, documentation, environment, libraries, packages, modules) have corresponding path entries

### Host Configuration Pattern

Hosts are defined as:
```nix
nixosConfigurations.HOSTNAME = mkHost "HOSTNAME" {};
```

Each host loads:
1. Common configuration from `Configuration/hosts/common/`
2. Host-specific configuration from `Configuration/hosts/HOSTNAME/`
3. User configurations for enabled users from `Configuration/users/USERNAME/`

## Development Commands

### NixOS System Management

**Rebuild the system** (wrapper with sane defaults):
```bash
nixrb [switch|boot|test|build] [--upgrade] [--trace]
```
The `nixrb` script in `Bin/shellscript/project/nix/nixrb` wraps `nixos-rebuild` with defaults.

**Manual rebuild**:
```bash
sudo nixos-rebuild switch --flake /home/craole/.dots#QBXvm
```

**Update flake inputs**:
```bash
nix flake update
```

### Development Environment

**Enter development shell**:
```bash
nix develop
```
Or use direnv (configured in `.envrc`):
```bash
direnv allow
```

### Code Formatting

**Format all code** (Rust, TOML, Deno-supported files, PowerShell, Justfiles):
```bash
just fmt
```
Or directly:
```bash
treefmt --allow-missing-formatter --clear-cache
```

Configuration in `.treefmt.toml` with formatters:
- Rust: `rustfmt`
- TOML: `taplo`
- JS/TS/JSON/Markdown/YAML/CSS: `deno fmt`
- PowerShell: custom formatter
- Justfiles: `just --fmt`
- Typst: `typstyle`
- YAML: `yamlfmt`

**Shell script linting**:
ShellCheck is configured in `.shellcheckrc` with:
- External sources enabled
- Severity level: style
- Source paths: script directory and `Bin/shellscript`
- Disabled checks: SC1090-SC1091 (source following), SC2034 (unused vars), SC2154 (unassigned vars)

### Version Control (jujutsu)

The repository uses `jj` (jujutsu) for version control:

**Quick commit and push**:
```bash
just push "commit message"
```

**Interactive commit**:
```bash
just push-interactive
```

### Testing

Currently only PowerShell tests exist in `Tests/powershell/`. No automated test runner is configured.

## Adding a New Host

1. Copy the example configuration:
```bash
host_conf="$DOTS/Configuration/hosts/$(hostname)"
host_conf_example="$DOTS/Configuration/hosts/example"
sudo mkdir -p "$host_conf"
sudo cp -u "$host_conf_example"/* "$host_conf"
sudo cp -u /etc/nixos/* "$host_conf"
```

2. Update `default.nix` with hardware configuration details from the system-generated `hardware-configuration.nix`

3. Add the host to `flake.nix`:
```nix
nixosConfigurations.HOSTNAME = mkHost "HOSTNAME" {};
```

4. Define host-specific settings in `Configuration/hosts/HOSTNAME/default.nix`:
- `platform`: System architecture (x86_64-linux, aarch64-darwin, etc.)
- `people`: List of enabled users
- `preferredRepo`: "stable" or "unstable" nixpkgs
- `allowUnfree`: Boolean for proprietary packages
- `flake`: Optional custom flake path override

## Custom Binary Development

### Shell Scripts

- Place in appropriate `Bin/shellscript/` subdirectory based on purpose
- Follow POSIX compatibility where possible
- Use ShellCheck pragmas for intentional violations
- Source common utilities from other scripts in `Bin/shellscript/`
- The `buildir` utility in `Bin/shellscript/environment/` builds PATH from nested directories

### Rust/Python/Nushell

- Place in respective `Bin/` subdirectories
- Rust binaries are managed via Nix where appropriate
- All binaries in `Bin/` subdirectories are automatically added to PATH via `buildir`

## Flake Structure

**Key Flake Outputs**:
- `nixosConfigurations`: NixOS system configurations
- `packages`: Custom packages via `Admin/Packages/custom/`
- `overlays`: Package overlays via `Admin/Packages/overlays/`
- `devShells.default`: Development shell with custom packages
- `lib`: Reusable library functions

**Important Flake Inputs**:
- `nixPackages`: Primary nixpkgs (unstable)
- `nixosHome`: home-manager for user environments
- `nixosDarwin`: nix-darwin for macOS
- `nixosWSL`: NixOS-WSL for Windows integration
- `styleManager`: stylix for system-wide theming
- `plasmaManager`: KDE Plasma configuration
- `secretManager`/`secretKey`/`secretShell`: agenix secret management ecosystem
- `treeFormatter`: treefmt-nix for code formatting

## Environment Variables

**Core variables** (set by `.dotsrc`):
- `DOTS`: Repository root path (must be set before sourcing `.dotsrc`)
- `DOTS_BIN`: Path to `Bin/` directory
- `DOTS_PATH`: Colon-delimited string of all `Bin/` subdirectories
- `DOTS_ENV`: Path to `Environment/` directory
- `DOTS_INIT_DURATION`: Initialization time in seconds

**Nix-specific**:
- Paths are managed through the `paths` special argument passed to all modules

## Shell Profiles

### POSIX Shells (bash/zsh/sh)

Add to `~/.profile`:
```bash
DOTS="$HOME/.dots"
export DOTS
[ -f "$DOTS/.dotsrc" ] && . "$DOTS/.dotsrc"
```

Ensure `~/.bashrc` sources `~/.profile`:
```bash
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
```

### Nushell

Add to `env.nu`:
```nushell
$env.DOTS = ($env.HOME | path join ".dots")
source ($env.DOTS | path join "Environment" "_.nu")
```

### PowerShell

Add to profile:
```powershell
$env:DOTS = "$HOME\.dots"
Import-Module "$env:DOTS\Configuration\powershell\profile.psm1" -Force
```

## License

Dual-licensed under Apache-2.0 and MIT (see `LICENSE-APACHE` and `LICENSE-MIT`).
