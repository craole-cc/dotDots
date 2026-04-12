# AGENTS

## Identity
- This repo is a Lix-centered Nix flake for cross-system dotfiles, host definitions, user profiles, and reusable config modules.
- `flake.nix` is the flake output entrypoint.
- Top-level `default.nix` assembles `lix`, `tree`, `schema`, `hosts`, and `users`.

## Open First
- `flake.nix`
- `default.nix`
- `Libraries/nix/modules/construction.nix`
- `Documentation/ai/ARCHITECTURE.md`

## Structure
- `Libraries/nix/*`: shared Lix infrastructure.
- `API/nix/hosts/*`: host source-of-truth.
- `API/nix/users/*`: user source-of-truth.
- `Modules/nix/core/*`: system behavior.
- `Modules/nix/home/*`: Home Manager behavior.
- `Templates/nix/*`: reusable kits exposed via `tree.store.kit.*`.

## Navigation Order
- Trace runtime flow as `flake.nix` -> `default.nix` -> `lix.modules.construction` -> `schema` / `tree` -> `API/nix` + `Modules/nix`.
- For host or user changes, inspect `API/nix` before touching modules.
- For reusable logic, inspect `Libraries/nix` before adding new patterns.

## More
- `ARCHITECTURE.md`: system model.
- `CONVENTIONS.md`: repository rules.
- `TASKS.md`: repeatable debugging and change entrypoints.
- `CODEX.md`: Codex-specific adapter.
