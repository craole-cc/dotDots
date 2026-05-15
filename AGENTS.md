# Repository Guidelines

## Project Structure & Module Organization

This repository is a cross-platform dotfiles and tooling monorepo. Keep changes scoped to the relevant area:

- `Configuration/`: app and shell configs such as `neovim/`, `git/`, `treefmt/`, and `just/`.
- `Libraries/`: reusable scripts and code by language (`bash/`, `powershell/`, `python/`, `rust/`, `nix/`).
- `Modules/` and `API/`: Nix modules and higher-level system/user definitions.
- `Packages/`: packaged deliverables, primarily Nix and Rust.
- `Templates/`: reusable project templates, especially Nix-based starters.
- `Tests/`: ad hoc test fixtures and PowerShell loader examples.
- `Assets/` and `Documentation/`: static resources and supporting docs.

## Build, Test, and Development Commands

Use repo-root commands unless you are working inside a specific subproject.

- `nix flake check`: run the main Nix checks for the repository.
- `treefmt --no-cache`: format supported files using the shared config in `Configuration/treefmt/config.toml`.
- `treefmt --fail-on-change --no-cache`: CI-style formatting check.
- `just --justfile Configuration/just/justfile format`: run the same formatter through the bundled `just` workflow.
- `pwsh -File Tests/powershell/Utils/hello.ps1`: quick smoke test for PowerShell loader examples.

If you touch a Rust-focused subproject, run `cargo test` and `cargo fmt` from that project directory, not from the repo root.

## Coding Style & Naming Conventions

Follow existing file-local conventions. Prefer ASCII unless the file already uses Unicode. Use 2 spaces in shell and config files; keep Rust formatted with `rustfmt`. File and directory names are usually lowercase, with hyphens or descriptive plain names; PowerShell modules use PascalCase-like names such as `Links.psd1`.

## Testing Guidelines

Validate the smallest relevant surface first, then run broader checks. For Nix changes, run `nix flake check`. For formatting-sensitive changes, run `treefmt --fail-on-change --no-cache`. Keep new test fixtures under `Tests/<language-or-area>/` and name PowerShell scripts descriptively, for example `testA.ps1` or `hello.ps1`.

## Commit & Pull Request Guidelines

Recent commits use short, lowercase subjects with an optional scope prefix, for example `documentation template: testing` or `moved data to exclusions`. Keep commits focused and imperative. PRs should explain what changed, why it changed, and any platform impact. Link related issues when applicable and include screenshots only for UI-facing config changes.
