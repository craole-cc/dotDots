# Nix Conventions

## Repository Roles

- Treat `API/nix` as data.
- Treat `Modules/nix` as behavior.
- Treat `Libraries/nix` as infrastructure.

## Working Rules

- Prefer reusable logic in `Libraries/nix` or `Modules/nix`; keep host- and user-specific choices in `API/nix`.
- Do not assume `default.nix` contains substantive logic. Many `default.nix` files are import aggregators.
- Expect aggregators to use `lix.filesystem.importers.importAll` or `importAllPaths`.
- Follow `tree.store.*` references when locating canonical module, API, or template paths.

## Change Heuristics

- If the change is about one machine, start in `API/nix/hosts/<host>/`.
- If the change is about one user’s apps, interface, or paths, start in `API/nix/users/<user>/`.
- If the change affects all hosts or all HM users, start in `Modules/nix`.
- If the change introduces a shared helper or abstraction, start in `Libraries/nix`.

## Avoid

- Duplicating host/user data inside modules.
- Introducing new path conventions when `tree` already models the location.
- Adding one-off module logic when a library helper would make the pattern reusable.
