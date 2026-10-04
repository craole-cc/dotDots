{
  lix,
  sources,
  pools,
  ...
}: let
  inherit (lix) inputs;
  inherit (lix.attrsets) attrByPath attrValues listToAttrs mapAttrs recursiveUpdate;
  inherit (lix.lists) concatMap elem elemAt filter length toList optional partition unique;
  inherit (lix.strings) concatStringsSep escapeShellArg isString mkPath splitString;

  /**
  Build the package set every other function in this file works against.

  The set is `nixpkgs` at the revision pinned in `registry.sources.nixpkgs`,
  with the requested overlays layered on and `allowUnfree`/`allowBroken`
  applied. Everything else here takes an already-built `pkgs` rather than
  calling this, because a kernel overlay in particular has to agree with the
  nixpkgs revision it was written against -- building a second set and
  mixing derivations across the two is the failure this parameter exists to
  avoid.

  Returns a nixpkgs instance: `{ system, lib, stdenv, <package>, ... }`.

  # Type

  ```nix
  mkNixPkgs :: {
    system : String,
    overlays : [ (final : prev : AttrSet) ],
    allowUnfree : Bool,
    allowBroken : Bool,
    config : AttrSet,
  } -> AttrSet
  ```
  */
  mkNixPkgs = {
    system,
    overlays ? [],
    allowUnfree ? config.allowUnfree or true,
    allowBroken ? config.allowBroken or false,
    config ? {},
    ...
  }:
    import sources.nixpkgs.path {
      inherit system overlays;
      config = recursiveUpdate config {
        inherit allowUnfree allowBroken;
      };
    };

  /**
  Resolve `registry.pools` against a package set.

  `registry.nix` splits fetched sources into two shapes, because
  `mkNixPkgs` accepts only the first and each behaves differently:

    :
    `overlays`
    a function of `(final, prev)`, layered onto the package set.
    `rust-overlay` contributes `rust-bin`.

    :
    `pools`
    a function of `{inputs, pkgs, mkPath, ...}` returning an attrset of
    derivations built against the set it was handed. The calling
    convention lives on the registry entry itself (`spec.apply`), because
    each source's shape is its own: `zen-browser`'s root import is
    `{pkgs}: {...}`, cachyOS's `loadPackages.nix` is curried and needs its
    flake inputs, `hermes-agent` leaks build internals that must be
    stripped, and `llm-agents` is a straight flake read.

  :
  `pkgs`
  A parameter rather than built here, because a kernel overlay has
  to agree with the nixpkgs revision it was written against: applying it to
  some other set produces either a build failure or a package linked across
  two nixpkgs.

  # Type

  ```nix
  mkSets :: AttrSet -> { <name> : AttrSet, pkgs : AttrSet }
  ```
  */
  mkSets = pkgs:
    (
      mapAttrs
      (name: spec: spec.apply {inherit inputs pkgs mkPath;})
      pools
    )
    // {inherit pkgs;};

  /**
  Build a single shell-ready command string from a package specification.

  The argument may be either a string or an attrset.  When it is an
  attrset the following optional fields are recognised:

    :
    `name`
    attribute name (required for attrsets)

    :
    `pkg`
    Nixpkgs attribute path (dotted). Defaults to `name`.

    :
    `stem`
    binary name inside `$out/bin`. Defaults to `name`.

    :
    `arguments`
    extra arguments (shell-escaped).

    :
    `pkgs`
    already-evaluated package set (highest priority).

    :
    `system`
    system string for `mkNixPkgs` when `pkgs` is absent. Derived from
    `host.system` when `host` is given and `system` is not.

    :
    `host`
    host attrset for `mkNixPkgs` when `pkgs` is absent.


  When neither `pkgs` nor a usable `system`/`host` is present,
  `mkNixPkgs` will throw.
  */
  mkBin = value: let
    spec =
      if isString value
      then {name = value;}
      else value;

    inherit (spec) name;

    pkg = spec.pkg or name;
    stem = spec.stem or name;
    args = spec.arguments or [];

    pkgs = spec.pkgs or mkNixPkgs (
      recursiveUpdate
      (spec.host.packages or {})
      (recursiveUpdate (spec.host or {}) spec)
    );
    
    executable =
      mkPath
      (attrByPath (splitString "." pkg) null pkgs)
      (["bin"] ++ toList stem);
  in {
    inherit name;
    value = concatStringsSep " " (
      [(escapeShellArg executable)]
      ++ map escapeShellArg args
    );
  };

  /**
  Turn a list of binary specifications into an attribute set of
  shell-escaped command strings.

  First argument is an attrset of defaults (`pkgs`, `host`, `system`)
  that are applied to every entry which does not already supply them.

  Examples:

  ```nix
  mkBins { inherit pkgs; } [
    "ripgrep"
    "fd"
    { name = "my-tool"; pkg = "myTool"; }
    { name = "special"; pkgs = someOtherPkgs; }
  ]

  mkBins { system = "x86_64-linux"; } [ "ripgrep" ]
  mkBins { inherit host; } [ "ripgrep" ]
  ```
  */
  mkBins = {
    pkgs ? null,
    host ? null,
    system ? null,
  }: bins: let
    withDefaults = value:
      if isString value
      then {
        name = value;
        inherit pkgs host system;
      }
      else
        value
        // {
          pkgs = value.pkgs or pkgs;
          host = value.host or host;
          system = value.system or system;
        };
  in
    listToAttrs (map (bin: mkBin (withDefaults bin)) bins);

  /**
  Convenience wrapper for the common case:

      mkBins' pkgs [ "ripgrep" "fd" ]
  */
  mkBins' = pkgs: mkBins {inherit pkgs;};

  resolvePackage = pkgs: name:
    pkgs.${name} or null;

  expandName = groups: stack: name:
    if elem name stack
    then throw "resolve packages: cyclic package group '${name}'"
    else if groups ? ${name}
    then
      concatMap
      (expandName groups (stack ++ [name]))
      groups.${name}
    else [name];

  expandNames = {
    groups,
    names,
  }:
    concatMap (expandName groups []) names;

  #? Where a requested name might actually live.
  #?
  #? Not every name is a nixpkgs attribute. Some name a package that only a
  #? fetched flake publishes (`hermes`), some name a variant inside a package-set
  #? function rather than a package at all (`zen-twilight`, which is `twilight`
  #? in zen''s set), and some differ from the package that satisfies them by a
  #? judgement the user should never have to know about. So resolution is a
  #? search across pools, in order, rather than one lookup.
  #?
  #? `pkgs` first, because an attribute that exists in nixpkgs is the least
  #? surprising answer and needs no table to justify it. `extra` follows, for
  #? the fetched pools -- the caller passes `mkSets`'s output here.
  #?
  #? `aliasOf` maps a requested name to `{source, name}`: where it lives, and
  #? what it is called there. `hermes` becomes
  #? `{source = "hermes-agent", name = "default"}`. The alias is a *judgement*
  #? about one name and cannot be derived -- `slugify "hermes"` is `"hermes"`,
  #? not `"hermes-agent"` -- so the table decides and nothing else does.
  #?
  #? A name that reaches the end has not been satisfied. That is a warning, not
  #? a failure: the caller decides, because a principal''s wish-list is
  #? best-effort and one absent tool should not cost the whole build. The error
  #? message lists the pools searched, so a name that *is* present somewhere is
  #? diagnosable from the message alone.
  resolvePackageGroups = {
    pkgs,
    groups,
    names,
    context,
    #? Additional pools, keyed by source name, searched after `pkgs`.
    #?
    #? Keyed rather than a bare list, because an alias names both the source and
    #? the attribute within it, and resolving only the attribute is not enough:
    #? nixpkgs publishes its own `chatgpt`, so a search that only renamed would
    #? still find the darwin-only one first. The key is what lets an alias pin
    #? the pool. `attrValues` turns it back into search order where needed.
    extra ? {},
    aliasOf ? name: null,
    #? Treat an unsatisfiable name as fatal rather than a warning. Off by
    #? default, because a principal's declarations are wishes.
    strict ? false,
  }: let
    expanded = unique (expandNames {inherit groups names;});

    preferredPool = name: let
      entry = aliasOf name;
    in
      if entry == null
      then null
      else extra.${entry.source} or null;

    resolvedName = name: let
      entry = aliasOf name;
    in
      if entry == null
      then name
      else entry.name;

    poolOf = name: let
      #? An alias pins the pool; with no alias, the first pool carrying the name
      #? wins, and nixpkgs leads because an attribute that exists there is the
      #? least surprising answer.
      preferred = preferredPool name;
      #? The membership test uses the *resolved* name, because that is what the
      #? pool will be indexed by. Testing the requested name would look for
      #? `hermes-desktop` in a pool keyed `desktop`, find nothing, and fall
      #? through to the unaliased search -- which lands back on nixpkgs.
      candidate = resolvedName name;
    in
      if preferred != null && preferred ? ${candidate}
      then preferred
      else let
        found =
          filter
          (pool: pool ? ${candidate})
          ([pkgs] ++ attrValues extra);
      in
        if found != []
        then elemAt found 0
        else null;

    #? Both the pool and the attribute come from the *requested* name, because
    #? the alias is keyed on how the user spelled it. Passing the already-resolved
    #? name here would look the alias up under `chatgpt`'s value rather than the
    #? request `chatgpt`, and miss.
    derivationOf = name: let
      candidate = resolvedName name;
      pool = poolOf name;
    in
      if pool == null
      then
        throw ''
          ${context}: package '${name}' was not found.
          Looked for '${resolvedName name}' in nixpkgs and ${
            toString (length extra)
          } fetched package set(s).
          Add it to the alias table if it lives under a different name.
        ''
      else pool.${candidate};

    #? What could not be found, and what was found anyway.
    #?
    #? A principal's declarations are *preferred*, best-effort wishes, not build
    #? invariants -- so an unsatisfiable request is dropped with a warning, not
    #? an error. Failing the whole build because one of thirty requested tools
    #? does not exist in any pool would make the tree unusable for exactly the
    #? reason it is expressive.
    #?
    #? `strict` is the opposite policy, for a name that is genuinely required --
    #? a kernel, or something the rest of the config dereferences. It is opt-in
    #? per call so the default stays forgiving.
    #?
    #? Reported together rather than one per name: a spec asking for three absent
    #? tools should say so once, not hide two behind the first failure.
    show = names: concatStringsSep ", " (map (name: "'${name}'") names);

    byPresence = partition (name: poolOf name != null) expanded;
    satisfied = byPresence.right;
    missing = byPresence.wrong;

    missingWarning =
      if (missing == [])
      then null
      else ''
        ${context}: wanted ${show missing}, which is in neither nixpkgs nor
        ${toString (length extra)} fetched package set(s). Dropping them.
      '';
  in
    if (missing != []) && strict
    then
      throw ''
        ${context}: no package for ${show missing}.
        Looked in nixpkgs and ${toString (length extra)} fetched package set(s).
        This name was required, so the build cannot continue -- either drop it
        from the spec or add it to the alias table.
      ''
    else {
      inherit satisfied missing;
      warnings = optional (missing != []) missingWarning;
      packages = map derivationOf satisfied;
    };
in {
  inherit
    mkBin
    mkBins
    mkBins'
    mkSets
    mkNixPkgs
    expandNames
    resolvePackage
    resolvePackageGroups
    ;
}
