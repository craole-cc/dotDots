# Architecture

## Core Model
- `flake.nix` defines inputs and delegates output construction to `lix.modules.construction.mkFlake` and host evaluation to `mkSystems`.
- Top-level `default.nix` is the local assembly point. It imports `Libraries/nix`, exposes the custom `lix` namespace, constructs `tree`, and derives `schema`.
- `tree` is the canonical path registry. Code refers to repo locations through `tree.store.*` instead of ad hoc relative paths.
- `schema` is built from `API/nix/hosts` and `API/nix/users`.

## Layers
- `Libraries/nix/*`: generic Lix library code for filesystem, schema, sources, modules, applications, options, lists, strings, and attrsets.
- `API/nix/*`: concrete host and user data.
- `Modules/nix/*`: reusable NixOS and Home Manager modules.
- `Modules/nix/global/*`: flake-level outputs such as `devShells`, `formatter`, and `checks`.

## Evaluation Flow
- `flake.nix` imports the repo root and receives `lix`, `tree`, `schema`, and `top`.
- `mkFlake` builds per-system flake outputs using `Modules/nix/global/default.nix`.
- `mkSystems` evaluates each host from `schema.hosts`.
- `mkSystems` resolves input packages and input modules, then builds host module args.
- `mkHome` wires Home Manager and uses `Libraries/nix/modules/home/users.nix` to attach per-user home configs.
- Home user configs import `tree.store.mod.home`, so `Modules/nix/home/*` becomes the shared HM behavior layer.

## Important Entrypoints
- `flake.nix`
- `default.nix`
- `Libraries/nix/modules/construction.nix`
- `Libraries/nix/schema/_.nix`
- `Libraries/nix/filesystem/tree.nix`
