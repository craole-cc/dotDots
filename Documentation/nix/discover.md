# Nix Discovery Notes

This document records the *discovered* shape of the repo’s Nix code, with a focus on what the implementation currently does rather than the intended abstract model.

Stable conceptual architecture lives in `Documentation/nix/architecture.md`. This file is the practical map: what to open first, where logic lives, and how the Nix layers connect in this repo.

---

## What This Repo’s Nix Stack Is Doing

At a high level, the repo is organized around a custom Nix library (`lix`) that drives the rest of the flake.

The runtime flow is:

```text
flake.nix
  -> default.nix
    -> Libraries/nix
    -> tree
    -> schema
    -> hosts/users
    -> Modules/nix
```

The important detail is that `Libraries/nix` is not just a helper folder. It is the repo’s internal framework layer:

- it builds the `lix` namespace
- it centralizes filesystem path modeling via `tree`
- it resolves flake inputs into canonical forms
- it assembles schemas, packages, and modules
- it exposes reusable constructors and validators used everywhere else

---

## Canonical Nix Entry Points

### `flake.nix`

This is the flake output driver.

It:
- defines external inputs
- imports the repo root
- receives `lix`, `tree`, `schema`, and `top`
- delegates flake output construction to `lix.modules.construction.mkFlake`
- delegates host evaluation to `mkSystems`

### top-level `default.nix`

This is the local assembly point.

It:
- imports `Libraries/nix`
- exposes the `lix` namespace
- builds `tree` via `lix.filesystem.tree.mkTree`
- builds `schema` via `lix.schema._.mkSchema`
- exports `lix`, `paths`, `tree`, `schema`, `hosts`, and `users`

This file is the practical bridge between the flake and the repository’s internal Nix infrastructure.

---

## What `Libraries/nix` Provides

`Libraries/nix` is the repo’s reusable Nix foundation.

It is structured as a layered standard library with these major concerns:

- `filesystem/` — path modeling, tree construction, import helpers, predicates
- `sources/` — flake input normalization, package/module resolution, overlay wiring
- `schema/` — host/user data normalization into structured evaluation inputs
- `modules/` — evaluation orchestration and module composition
- `attrsets/`, `lists/`, `strings/`, `types/`, `debug/` — general-purpose utilities and validation helpers
- `options/` — option construction helpers

The library is self-assembling:
- `Libraries/nix/default.nix` imports the library root
- `Libraries/nix/internal/default.nix` scans and assembles the modules
- modules export `__docs`, `__tests`, and `__rootAliases` in addition to their functions

This means the library is designed to behave like a typed, documented API rather than a pile of ad hoc helpers.

---

## The `tree` Model

`Libraries/nix/filesystem/tree.nix` is the canonical repo-path registry.

It defines the named stems that other code relies on, so the repo can reference locations as structured values instead of hardcoded relative paths.

Important shapes:

- `tree.store.lib.nix` → `Libraries/nix`
- `tree.store.mod.core` → `Modules/nix/core`
- `tree.store.mod.home` → `Modules/nix/home`
- `tree.store.api.hosts` / `tree.store.api.users` → source-of-truth data
- `tree.store.kit.*` → reusable templates
- `tree.store.pkg.*` → package-related tree locations
- `tree.store.cfg.*` / `tree.store.env.*` → config/environment paths

Key observation:
- `tree` is not a convenience wrapper
- it is the repo’s canonical location API

If a path already exists in `tree`, prefer using that over inventing a new relative import.

---

## Data vs Behavior vs Infrastructure

The repo is intentionally split into three roles:

### `API/nix`
Data only.

Contains the source of truth for:
- hosts
- users
- host-specific declarations
- user-specific preferences

### `Modules/nix`
Behavior.

Contains the reusable module logic for:
- NixOS system behavior
- Home Manager behavior
- global flake outputs
- host/user module composition

### `Libraries/nix`
Infrastructure.

Contains the reusable machinery that makes the other layers work:
- tree/path resolution
- schema construction
- module assembly
- input normalization
- package resolution
- validation, docs, and tests

This split is one of the strongest patterns in the repo and should be preserved when adding new code.

---

## What I Discovered in the Module Pipeline

### `Libraries/nix/modules/construction.nix`

This is the orchestration layer.

It defines:
- `mkSystems`
- `mkFlake`
- `mkCore`
- `mkHome`
- `mkTree` re-exported in the module construction namespace

Important behavior:
- `mkSystems` evaluates each host from `schema.hosts`
- it resolves packages and modules from flake inputs
- it builds host `specialArgs`
- it evaluates module graphs through `evalModules`
- Darwin hosts also expose a built system derivation under `system`

### `Libraries/nix/modules/home/users.nix`

This builds the `home-manager.users` attrset.

It:
- turns schema users into HM user configs
- derives per-user paths and environment context
- injects user-facing module args like `style`, `apps`, `keyboard`, `locale`, `paths`
- conditionally imports feature modules from resolved home modules

### `Libraries/nix/modules/core/*.nix`

These define the system-side behavior stack.

In this repo, “core” is the host/system layer that wires Home Manager, packages, services, and other system behavior into a host configuration.

---

## Input and Package Resolution

### `Libraries/nix/sources/inputs.nix`

This normalizes flake inputs into a canonical internal shape.

It handles:
- alias resolution
- case-insensitive lookup
- stable/unstable nixpkgs selection
- source extraction for Darwin vs NixOS consumers

### `Libraries/nix/sources/modules.nix`

This resolves module sets from flake inputs.

It distinguishes between:
- core system modules
- home-manager modules
- per-input module families

### `Libraries/nix/sources/packages.nix`

This resolves packages and overlays from flake inputs.

It builds:
- `nixpkgs`
- overlays
- package sets
- host-specific package config

The pattern here is consistent: external flakes are normalized first, then converted into a shaped internal API.

---

## Schema Discovery

### `Libraries/nix/schema/_.nix`

This turns `API/nix` data into evaluable structures.

It imports host and user directories and then enriches host records through `mkCore`.

The result is a structured schema with:
- `hosts`
- `users`

This is the bridge between static repo data and evaluated system configuration.

---

## File/Module Conventions I’ve Observed

These conventions are visible across the Nix codebase:

- `mk*` usually constructs or derives something
- `get*` usually resolves or retrieves something
- `normalize*` usually cleans or canonicalizes input
- `resolve*` usually turns deferred or ambiguous input into a concrete shape
- `__docs` is used for module-level documentation
- `__tests` carries module tests
- `__rootAliases` exposes the public alias surface
- `default.nix` is often an aggregator, not necessarily behavior
- long files use explicit docstrings and section headers to stay navigable

The repo strongly prefers:
- explicit contracts
- named exports
- structured attrsets
- validation over silent coercion
- reusable helpers over local duplication

---

## What This Means for Future Changes

If you are adding or changing Nix code in this repo:

- use `tree` if the change touches a repo path
- use `API/nix` if the change is host/user data only
- use `Modules/nix` if the change is reusable behavior
- use `Libraries/nix` if you need a new shared helper or abstraction
- check whether a `default.nix` is only an aggregator before editing it
- prefer extending existing library machinery rather than writing one-off logic in modules

---

## Quick Navigation Map

For common investigations:

- flake outputs → `flake.nix`, `Modules/nix/global/default.nix`
- host evaluation → `API/nix/hosts/*`, `Libraries/nix/schema/_.nix`, `Libraries/nix/modules/construction.nix`
- home evaluation → `API/nix/users/*`, `Libraries/nix/modules/home/users.nix`
- tree/path resolution → `default.nix`, `Libraries/nix/filesystem/tree.nix`
- input normalization → `Libraries/nix/sources/inputs.nix`
- package resolution → `Libraries/nix/sources/packages.nix`
- module resolution → `Libraries/nix/sources/modules.nix`
- shared helpers → `Libraries/nix/*`

---

## Practical Summary

The repo’s Nix code is built around a single idea:

> *Model the repository itself as structured data, then use the library layer to turn that structure into evaluated systems.*

That is why `Libraries/nix` matters so much: it is the infrastructure that keeps the rest of the flake coherent.
