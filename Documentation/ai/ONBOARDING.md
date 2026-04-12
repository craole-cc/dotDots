# ONBOARDING

This document is the canonical agent onboarding guide for this repository.
Tool-specific adapters (`CODEX.md`, `CURSOR.md`, etc.) should reference this
file rather than duplicate its content.

---

## What This Repo Is

A Lix-centered Nix flake for cross-system dotfiles, host definitions, user
profiles, and reusable configuration modules. It is not a simple home-manager
wrapper — it has a fully custom library (`lix`) and a typed schema system
driving host and user evaluation.

The three most important mental-model facts:

1. `lix` is the custom standard library. Everything flows through it.
2. `tree` is the canonical path registry. Paths are never hardcoded — they are
   looked up through `tree.store.*`.
3. The repo is divided into four strictly separated roles: `Libraries/nix`
   (infrastructure), `API/nix` (data), `Modules/nix` (behavior),
   `Templates/nix` (reusable kits).

---

## Self-Guided Exploration Sequence

Follow this order on first contact with the repo. Do not skip steps.

### Step 1 — Orient

Read `flake.nix` and `default.nix` in full.

From `flake.nix` you will learn:

- All external inputs and what they provide (editors, shells, styling, secrets,
  formatters, etc.).
- That `mkFlake` and `mkSystems` drive output construction — these are defined
  inside `Libraries/nix`.
- That `inputsWrapped` normalises inputs before they reach modules.

From `default.nix` you will learn:

- The full directory tree expressed as `stems` — this is the authoritative
  path map. Every path in the repo has a `tree.store.*` equivalent.
- That `lix` is imported from `Libraries/nix` and exposed as the shared
  namespace.
- That `schema` is derived from `tree` and produces `hosts` and `users`.

### Step 2 — Read the Architecture

Read `Documentation/ai/ARCHITECTURE.md`.

This gives you the evaluation flow:

```sh
flake.nix
  -> default.nix          (assembles lix, tree, schema)
  -> lix.modules.construction
      -> mkFlake           (per-system outputs: devShells, formatter, checks)
      -> mkSystems         (evaluates each host from schema.hosts)
          -> mkCore        (NixOS system config from Modules/nix/core)
          -> mkHome        (Home Manager config from Modules/nix/home)
```

### Step 3 — Learn the Library Conventions

Open any module under `Libraries/nix/` and read it with these questions in mind.

#### Module signature

Every `lix` module takes `{ _, ... }` as its argument set. The `_` argument is
the entire `lix` namespace — the library itself, passed as a single attrset.
Modules never use relative imports; they access everything through `_`.

#### Module structure (canonical ordering)

Every module follows this ordering:

```nix
{ _, ... }: let
  __doc = ''...'';        # 1. documentation string
  __exports = { ... };    # 2. internal and external export declarations
  __imports = { ... };    # 3. all inherit statements, collected here
  # 4. functions, each preceded by its /** */ docstring
in
  __exports.internal // {
    _rootAliases = __exports.external;
    inherit __doc;
    _tests = runTests { ... };
  }
```

Do not deviate from this ordering when writing or editing modules.

#### `__doc`

A multiline string with this format:

```sh
<Title> (Layer N).

<2–4 sentences describing what this module provides.>

Depends on: <comma-separated list>
```

The layer number and `Depends on:` line are mandatory. Read them to understand
the module's place in the dependency graph before editing. Leaf modules (no
intra-domain dependencies) omit the `Depends on:` line.

#### `__exports`

Exports are split into `internal` and `external`:

```nix
__exports = {
  internal = {
    inherit fnOne fnTwo;          # bare names, used within the module tree
  };
  external = {
    #~@ prefixed to avoid root-level collisions
    domainFnOne = fnOne;          # namespaced: <domain><FunctionName>
    domainFnTwo = fnTwo;
  };
};
```

Internal exports use bare `inherit`. External exports **must be namespaced**
with the domain prefix to avoid collisions at the root level — e.g.
`toApplicationPath`, `mkUserConfig`, `hasCapabilitySync`. Bare `inherit` in
`external` is only appropriate when the name is already globally unambiguous.

External exports surface as `_rootAliases` in the `in` clause and become
available directly on the `_` namespace at the root level.

#### `__imports`

All `inherit` statements that pull from `_` are collected in `__imports`:

```nix
__imports = {
  inherit (_.some.namespace) foo bar;
  inherit (_.other.namespace) baz;
};
```

Functions then open `__imports` with `with __imports;` rather than scattering
`inherit` statements throughout the body.

#### Function docstrings (`/** */`)

Every exported function is preceded by a `/** */` docstring in this order:

1. One-line summary (plain prose, no heading)
2. Optional second paragraph for edge cases, defaults, or guards
3. `# Type` block — pseudo-signature using `::`, named record args, `|` for
   unions, `?` suffix or inline comment for optionals
4. `# Examples` block — at minimum one typical case and one boundary/edge case,
   each with a comment explaining what it demonstrates

<!-- ```nix
  /**
    One-line summary of what the function does.

    Optional second paragraph for edge cases or defaults.

    # Type
  ```nix
    fnOne :: {
      argA :: string,
      argB :: int,      # optional, default 0
    } -> AttrSet
  ```

  # Examples

  ```nix
    fnOne { argA = "x"; }
    # => { ... }

    # Demonstrates behaviour when argB is omitted
    fnOne { argA = "x"; argB = 0; }
    # => { ... }
  ```

  */
  fnOne = with __imports; { argA, argB ? 0 }: ...;

``` -->

#### Naming prefix conventions

| Prefix       | Meaning                                       |
|--------------|-----------------------------------------------|
| `mk*`        | Constructor — builds or derives something     |
| `to*`        | Converter — transforms input to output        |
| `has*`       | Predicate — boolean, checks presence          |
| `is*`        | Predicate — boolean, checks identity/state    |
| `normalize*` | Cleaner — strips nulls, sentinels, empties    |
| `keysFrom*`  | Extractor — derives canonical key sets        |
| `resolve*`   | Resolver — materialises a deferred value      |

#### Generated attrset key prefixes

When a `mk*` function partitions an attrset and names the resulting keys, the
prefix encodes the semantic relationship:

| Prefix           | Relationship                          | Example              |
|------------------|---------------------------------------|----------------------|
| `by`             | grouped by field value                | `byColor`            |
| `is`             | boolean true partition                | `isStable`           |
| `has`            | list-field membership                 | `hasSync`            |
| `as`             | identity/role partition               | `asGraphical`        |
| `for`            | protocol or lang affinity             | `forWayland`         |
| `on`             | surface or channel partition          | `onWayland`          |
| `in`             | color or space membership             | `inDark`             |
| `with`           | toolkit or panel association          | `withGtk`            |
| `using`          | compositor affiliation                | `usingHyprland`      |
| `via`            | delivery mechanism                    | `viaGreeter`         |
| `from`           | family origin                         | `fromFirefox`        |
| `writtenIn`      | engine/language membership            | `writtenInRust`      |
| `supports`       | capability or protocol support        | `supportsWayland`    |
| `configuredWith` | config language                       | `configuredWithToml` |
| `single`/`multi` | list-length partition                 | `singleTag`          |

#### Section shape

When a `mk*` function produces a queryable section it always has this shape:

```nix
{
  all     = set;       # the full unfiltered set
  default = set;       # the set presented by default (may equal all)
  groups  = { ... };  # partitioned by field values
  queries = { ... };  # filtered by predicates and memberships
}
```

#### Tests (`_tests`)

Tests live in the `in` clause under `_tests = runTests { ... }`. Test names
read as assertions about behaviour, not descriptions of the function:

| Pattern | Use |
| --- | --- |
| `allowsX` / `deniesX` | boolean predicates |
| `returnsX` / `exportsX` | value or shape checks |
| `resolvesX` | lookup or alias resolution |
| `caseSensitiveWithExact` | case-sensitivity behaviour |

Cover at minimum: the happy path, the rejection path, and any default-value or
case-sensitivity behaviour.

#### Inline comment sigils

| Sigil | Use                                              |
|-------|--------------------------------------------------|
| `#~@` | groups, lists, collections                       |
| `#>`  | runners, verbs, active steps                     |
| `#?`  | checks, guards, questions, preconditions         |

Section headings in long files use box-drawing characters:

```nix
#╔═══════════════════════════════════════════════════════════╗
#║ Heading Text                                              ║
#╚═══════════════════════════════════════════════════════════╝
```

#### Type conventions

| Pattern                    | Meaning                                  |
|----------------------------|------------------------------------------|
| `string` `bool` `int`      | primitives                               |
| `AttrSet`                  | untyped attribute set                    |
| `{ ${key} :: AttrSet }`    | attrset with dynamic keys                |
| `A \| B`                   | union / nullable (`string \| null`)      |
| `# optional, default ""`   | optional record field with default       |
| `-> X \| {}`               | may return empty attrset                 |

#### Aggregator `default.nix`

Many `default.nix` files are pure aggregators. They use
`lix.filesystem.importers.importAll` or `importAllPaths` to load every sibling
file and re-export them as a merged attrset. Do not assume a `default.nix`
contains substantive logic — verify before reading it as a source of truth.

### Step 4 — Locate the API

Browse `API/nix/hosts/` and `API/nix/users/`.

Host files are data, not behavior. A host definition declares what a machine
is (its hardware, role, inputs, modules, and user assignments) but contains no
module logic. `mkSystems` in `Libraries/nix/modules/construction.nix` reads
this data and evaluates it.

User files are similarly declarative. They describe user identity, app
preferences, shell config, and theme choices. `mkHome` wires them into
Home Manager via `Libraries/nix/modules/home/users.nix`.

### Step 5 — Inspect the Module Layers

Open `Modules/nix/global/default.nix`. This is where `devShells`, `formatter`,
and `checks` are defined for the flake outputs.

Open `Modules/nix/core/default.nix`. This is the NixOS system behavior layer —
shared across all hosts.

Open `Modules/nix/home/default.nix`. This is the Home Manager behavior layer —
shared across all users.

For each file, check first whether it is an aggregator or a substantive module.

---

## Key Relationships to Hold

```yml
Libraries/nix
  provides: lix namespace, filesystem tools, schema constructors,
            module builders, application registry and query system

API/nix
  consumes: schema constructors from Libraries/nix
  provides: concrete host and user data

Modules/nix
  consumes: lix, tree, schema, API data, external inputs
  provides: NixOS and HM module behavior

Templates/nix
  consumes: lix, tree
  provides: reusable kit sets exposed via tree.store.kit.*

flake.nix
  wires: all of the above into flake outputs and nixosConfigurations
```

---

## Change Heuristics

Before editing anything, answer: what kind of change is this?

- **One machine differs from others** → `API/nix/hosts/<host>/`
- **One user's apps, shell, or theme** → `API/nix/users/<user>/`
- **Behavior that affects all hosts** → `Modules/nix/core/`
- **Behavior that affects all HM users** → `Modules/nix/home/`
- **Flake outputs, devShells, formatter** → `Modules/nix/global/`
- **A new shared helper or abstraction** → `Libraries/nix/`
- **A reusable template or kit** → `Templates/nix/`

When in doubt: is it data or behavior? Data belongs in `API/nix`. Behavior
belongs in `Modules/nix`. Infrastructure belongs in `Libraries/nix`.

---

## What to Verify Before Editing

1. Does `tree` already model the path you intend to add? Check `default.nix`
   stems before introducing new path conventions.
2. Is the `default.nix` you are about to edit an aggregator or does it own
   behavior? Open it and check before assuming.
3. Does a library helper already exist for the pattern you are about to write?
   Check `Libraries/nix/` before adding new logic to a module.
4. Are you putting data in a module or behavior in API? Both are wrong.

---

## Reference Documents

| Document | Contents |
| --- | --- |
| `ARCHITECTURE.md` | Evaluation flow and layer model |
| `CONVENTIONS.md` | Repository rules and role boundaries |
| `TASKS.md` | Investigation flows for common change types |
| `AGENTS.md` | Quick-reference navigation guide |
| Tool-specific adapters | `CODEX.md`, `CURSOR.md`, etc. |

---

## For Tool-Specific Adapters

Adapters should:

1. Tell the agent to read this file first.
2. Add only tool-specific notes (file watching, shell commands, diff format,
  model-specific constraints).
3. Not duplicate content from this file or from `ARCHITECTURE.md`,
   `CONVENTIONS.md`, or `TASKS.md`.

Example adapter structure:

```md
# <TOOL> Adapter

Read `Documentation/ai/ONBOARDING.md` before this file.

## Tool-Specific Notes

- ...
```
