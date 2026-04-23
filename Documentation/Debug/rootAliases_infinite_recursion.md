# Debug: Infinite Recursion with `rootAliases = true` in Custom Nix Library

## Context

This repo contains a custom Nix library loader located in `./Libraries/nix/`. It assembles
a namespaced, extensible attribute set (called `lix`) from `.nix` files found under that
directory. The library is built using `lib.fixedPoints.makeExtensible` (fixed-point
semantics), so all modules receive `self` (the final fixed point of the library) via
an `env` record as `_` and `x`.

## Problem

Infinite recursion occurs at runtime **only when `rootAliases = true`** is passed to
`Libraries/nix/default.nix`. When `rootAliases = false` (the default), the library builds
and evaluates correctly. The error surfaces at:

Libraries/nix/applications/groups.nix:31:9
all = \_.applications.filters.groups;
^

Where `_` is `self` — the extensible library's fixed point.

## Error Trace (truncated)

error: infinite recursion encountered
at Libraries/nix/applications/groups.nix:31:9:
all = \_.applications.filters.groups;

text

Run with `--show-trace` to get the full trace if not already visible.

## Files to Examine

Please read and reason over the following files (relative to repo root):

- `Libraries/nix/default.nix` — entry point, receives `rootAliases` flag
- `Libraries/nix/internal/default.nix` — builds the `library` via `makeExtensible`;
  contains the `rootAliases` branch logic
- `Libraries/nix/internal/env.nix` — constructs the module environment; `_ = self`
- `Libraries/nix/internal/scan.nix` — recursively scans `.nix` files; extracts
  `_rootAliases` from each imported module
- `Libraries/nix/internal/meta.nix` — `mkModuleExports` helper that creates
  `__rootAliases` (double underscore)
- `Libraries/nix/internal/assemble.nix` — final assembly; wraps `library` into `lix`
- `Libraries/nix/applications/groups.nix`— the file where recursion is detected; examine
  how it defines `_rootAliases`, what it exports,
  and whether it uses `mkModuleExports`

## What to Investigate

### 1. Attribute name strictness (primary suspect)

Nix's `//` operator is **strict in attribute names** of both operands. In
`internal/default.nix`, the `rootAliases = true` branch does:

```nix
rootAliasNames = attrNames results.rootAliases;
# ...
results.modules // results.rootAliases
```

Both `attrNames results.rootAliases` and the `//` operator force evaluation of the
**key set** of `results.rootAliases`. Trace whether computing those keys anywhere
requires forcing `_.applications.filters.groups` (i.e., `self.applications...`), which
itself requires `self` to already be fully resolved — creating a cycle.

Specifically check: does any module's `_rootAliases` attribute set have **dynamically
computed keys** that involve `_`/`self`? For example:

```nix
_rootAliases = builtins.listToAttrs (
  map (x: { name = x.id; value = x.fn; }) (_.applications.filters.groups)
);
```

This would be fatal because `attrNames` of `_rootAliases` forces `_.applications.filters.groups`
before `self` is constructed.

### 2. Naming mismatch: `_rootAliases` vs `__rootAliases`

`scan.nix` extracts: `rootAliases = importedModule._rootAliases or {};`
`meta.nix`'s `mkModuleExports` creates: `__rootAliases = mkExternal functions;`

These names do NOT match. Check whether:
a) `groups.nix` (and other modules) define `_rootAliases` directly rather than relying
on `mkModuleExports`
b) Or if there's a transform somewhere that renames `__rootAliases` → `_rootAliases`

If modules use `mkModuleExports` but scan looks for `_rootAliases`, then
`results.rootAliases` should always be `{}` when `rootAliases = true`, and the
`rootAliases = true` branch should be a no-op — yet it still causes infinite recursion.
This would mean something else triggers the cycle.

### 3. `filterAttrs` forcing values during `__meta` construction

In `scan.nix`, `processNixFile` builds `moduleWithMeta` with:

```nix
functions = attrNames (filterAttrs (_: v: isFunction v) cleanModule);
values    = attrNames (filterAttrs (_: v: !isFunction v) cleanModule);
```

`filterAttrs` tests **every value** in `cleanModule` with `isFunction v`, which
forces each thunk. If any module value is `all = _.applications.filters.groups` and
the thunk is forced here during scan, it may attempt to resolve `self.applications`
while `self` is still being assembled.

Check whether this forces the recursion in BOTH `rootAliases = true` AND `false` paths,
or only one. If only `true`, confirm what makes `self.applications` resolvable in the
`false` case but not the `true` case.

### 4. Cycle path when `rootAliases = true`

Trace the exact evaluation chain:

self = results.modules // results.rootAliases
↓ (// forces attrNames of results.rootAliases)
attrNames results.rootAliases
↓ (results.rootAliases built from foldlAttrs over processNixFile outputs)
processNixFile "groups.nix"
↓ (extracts importedModule._rootAliases or forces values via filterAttrs)
importedModule = rawModule moduleEnv (moduleEnv contains_ = self)
↓ (evaluating the module or its _rootAliases forces:)
all =_.applications.filters.groups = self.applications.filters.groups
↓ (self.applications requires knowing attrNames of results.rootAliases for //)
attrNames results.rootAliases ← CYCLE

Confirm or refute this exact chain. If refuted, trace the actual path using
`--show-trace` output.

### 5. Why `rootAliases = false` doesn't cycle

When `rootAliases = false`, `self = results.modules` (no `//`). Accessing
`self.applications` directly projects into `results.modules.applications`, which
is a concrete attrset built from directory scanning — no `attrNames results.rootAliases`
is ever needed. The `results.modules.applications` key is determinable from
`readDir` output alone, without evaluating any module body.

## Expected Output from Codex

1. **Identify the precise evaluation sequence** that causes the cycle (show the chain
   of forced thunks)
2. **Confirm or deny the `_rootAliases` vs `__rootAliases` naming mismatch** and whether
   it's a related or separate bug
3. **Propose a fix** — likely one or more of:
   - Wrap `rootAliases` value expressions with `builtins.unsafeDiscardStringContext` or
     use `lib.lazyDerivation`-style indirection
   - Separate root alias **key computation** from `self` references (use static string
     keys; keep only values lazy)
   - Rename `__rootAliases` → `_rootAliases` in `meta.nix` if that's the mismatch
   - Use `lib.mapAttrs` instead of `//` to avoid strict key evaluation during
     library construction
   - Move root alias merging to `assemble.nix` (post-construction) so `self` is
     already resolved before rootAliases are integrated
4. **Provide a minimal reproducible test** in `nix repl` that demonstrates the cycle
   in isolation

## Constraints

- The fix must preserve the existing module environment API (`_`, `x`, `s`, `l`, `libs`)
- Modules using `mkModuleExports` should not need to be rewritten
- `rootAliases = false` must remain unaffected
- The fix should not break the `collisionStrategy` handling in `internal/default.nix`
