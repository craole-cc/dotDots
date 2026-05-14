# CODEX

This file is a repo-specific adapter for Codex. Use `Documentation/ai/AGENTS.md`
as the primary entrypoint.

## Codex Focus

- Start from `flake.nix` and top-level `default.nix` before editing Nix code.
- Prefer tracing through `tree.store.*` rather than assuming raw relative paths
  are authoritative.
- When a task appears host-specific or user-specific, verify whether the real
  source-of-truth is under `API/nix` before editing `Modules/nix`.
- When editing a module subtree, check whether the local `default.nix` is only
  an aggregator before assuming it owns behavior.

## Boundaries

- Architecture details live in `ARCHITECTURE.md`.
- Repo rules live in `CONVENTIONS.md`.
- Investigation flows live in `TASKS.md`.
