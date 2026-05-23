# Shared Nix Style

These are the style rules that apply across the repo’s Nix code.

## Shared principles

- Prefer small, composable functions.
- Treat attrsets as APIs, not just containers.
- Validate early and fail with descriptive errors.
- Keep names stable and semantically meaningful.
- Prefer explicit exports over implicit behavior.
- Model repo structure through `tree.store.*` instead of raw relative paths.
- Keep data in `API/nix`, behavior in `Modules/nix`, and reusable infrastructure in `Libraries/nix`.

## Naming style

Prefer names that describe the semantic role, not the implementation detail.

Common prefixes and shapes:

- `mk*` for constructors
- `get*` for retrieval
- `resolve*` for materialization
- `normalize*` for canonicalization
- `with*` / `from*` / `to*` / `has*` / `is*` for semantic helpers

## Documentation style

Good docs are:

- heading-driven
- example-heavy
- explicit about boundaries
- practical about where to look next

Good doc sections usually include:

- what the file does
- what it depends on
- examples
- when to use it
- what not to use it for

## Testing style

Tests are usually close to the implementation and read like behavior statements.

Prefer test names that describe the guarantee being checked, such as:

- `trueKeyContainsFlaggedItems`
- `falseKeyContainsUnflaggedItems`
- `usesCallerSuppliedKeys`

## What to avoid

- hardcoding repo paths when `tree` already models them
- using one giant file when a smaller library module would be clearer
- inventing new export conventions for Nix modules
- hiding behavior in `default.nix` when the file is really just an aggregator
- duplicating data from `API/nix` into modules
