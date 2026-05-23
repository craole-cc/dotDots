# Nix Tasks

This file collects common inspection paths for the repo’s Nix code.

## Investigate flake outputs

- Open `flake.nix`.
- Open `Modules/nix/global/default.nix`.
- If output shape is unclear, open `Libraries/nix/modules/construction.nix` and inspect `mkFlake`.

## Investigate host evaluation

- Open `API/nix/hosts/<host>/default.nix`.
- Open `Libraries/nix/schema/_.nix`.
- Open `Libraries/nix/modules/construction.nix` and inspect `mkSystems` / `mkCore`.

## Investigate Home Manager behavior

- Open `Libraries/nix/modules/home/users.nix`.
- Open `Modules/nix/home/default.nix`.
- Then open the relevant subtree under `Modules/nix/home/*`.

## Investigate user preferences

- Open `API/nix/users/<user>/default.nix`.
- Then inspect `programs/`, `services/`, or nested app config under that user.
- If behavior is synthesized, trace into `Libraries/nix/schema/*` and `Libraries/nix/modules/home/*`.

## Investigate path or import resolution

- Open `default.nix` to inspect tree stems.
- Open `Libraries/nix/filesystem/tree.nix`.
- Open `Libraries/nix/filesystem/importers.nix`.

## Decide where a change belongs

- Data only: `API/nix`
- Shared module behavior: `Modules/nix`
- Cross-cutting helpers or abstractions: `Libraries/nix`
- Flake outputs, shells, formatter, checks: `Modules/nix/global`
