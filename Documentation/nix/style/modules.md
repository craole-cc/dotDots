# Module Style

This guide covers the style used in `Modules/nix`.

Modules should describe behavior clearly and keep their public surface easy to discover.

## Typical shape

Modules usually follow a predictable shape:

1. import only what is needed with `inherit`
2. define a docstring for the public function
3. keep helper data close to the function that uses it
4. export through `__docs`, `__tests`, and `__rootAliases`

## Example: module export pattern

```nix
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
    __tests = runTests { ... };
  }
```

This pattern keeps module surfaces structured and discoverable.

## Module behavior to prefer

- make behavior explicit in the module name and exports
- keep host/home composition code at the boundary, not buried inside helpers
- use small helper values instead of one large opaque attrset
- separate configuration data from evaluation logic when possible
- make module inputs visible through argument names and docs

## Common module boundaries in this repo

- `Modules/nix` carries behavior
- `API/nix` carries data
- `Libraries/nix` carries reusable infrastructure

When you are choosing where a change belongs, keep that split intact.

## What to avoid

- putting orchestration inside a leaf module when a central constructor already owns it
- hiding behavior in `default.nix` when the file is only an aggregator
- creating a module surface that cannot be understood without reading private helpers first
