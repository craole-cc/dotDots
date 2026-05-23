# API Style

This guide covers data-shape conventions for `API/nix`.

`API/nix` is the source of truth for repo data, so the main goal is stability and clarity rather than behavior.

## Typical characteristics

API data should be:

- declarative rather than procedural
- shaped for downstream consumers
- stable in naming and nesting
- free of reusable logic that belongs in `Libraries/nix`
- free of behavior that belongs in `Modules/nix`

## Data-shape rules

- keep records explicit and readable
- prefer semantic field names over implementation details
- make host/user data easy to discover and extend
- do not duplicate normalization logic here
- do not hide computed behavior in data files

## Example: source-of-truth data

The repo treats things like host and user declarations as data, not behavior.

That means `API/nix` should hold the definitions, while `Libraries/nix` handles normalization and `Modules/nix` handles behavior built from those definitions.

## Good API habits

- prefer stable schemas over clever abstractions
- keep data layout aligned with how consumers read it
- use names that reflect domain concepts
- leave validation and transformation to the library layer when possible

## What to avoid

- importing lots of machinery into API data files
- embedding reusable logic that belongs in libraries
- smuggling module behavior into declarative data
- changing field names casually without updating consumers
