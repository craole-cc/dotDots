{
  lix,
  modules,
  packageSets ? [],
  packageLoaders ? {},
  packageFlakes ? [],
  ...
}: let
  inherit (lix) inputs;
  inherit (lix.attrsets) attrByPath attrValues listToAttrs mapAttrs optionalAttrs removeAttrs;
  inherit (lix.lists) concatMap elem foldl' toList unique;
  inherit (lix.strings) concatStringsSep escapeShellArg isString mkPath splitString;
  inherit (lix.trivial) id;
  inherit (modules) mkNixPkgs;

  /**
  Resolve the sources that are *not* overlays, against a package set.

  `registry.nix` splits fetched sources into three shapes, because
  `mkNixPkgs` accepts only the first and each behaves differently:

    overlays     a function of `(final, prev)`, layered onto the package
                 set. `rust-overlay` contributes `rust-bin`.

    packageSets  a function of `{pkgs, ...}` returning an attrset of
                 *derivations* built against the set it was handed.
                 `zen-browser` exports `twilight`, `beta` and `default`,
                 so a name in a spec selects a key from this rather than
                 resolving a top-level attribute.

    loaders      an entry point named within the fetched tree, called with
                 positional arguments. cachyOS needs this because its root
                 `default.nix` is a flake-compat shim that fetches
                 flake-compat and reads `flake.lock`; `loadPackages.nix`
                 takes `(inputs, pkgs)` and returns every
                 `linux-cachyos-*` and `linuxPackages-cachyos-*` name.

  `pkgs` is a parameter rather than built here, because a kernel overlay has
  to agree with the nixpkgs revision it was written against: applying it to
  some other set produces either a build failure or a package linked across
  two nixpkgs.

  # Type

  ```
  mkSets :: {
    pkgs : AttrSet,
    sources : AttrSet,
    packageSets : [String],
    loaders : AttrSet,
  } -> { packageSets : AttrSet, loaders : AttrSet, pkgs : AttrSet }
  ```
  */
  mkSets = {
    pkgs,
    sources ? inputs,
    pkgSets ? packageSets,
    pkgLoaders ? packageLoaders,
    pkgFlakes ? packageFlakes,
  }: let
    resolved = {
      #? Every pool a name may live in, keyed by the source it came from. `pkgs`
      #? is folded in under its own name below, so `resolvePackageGroups` can
      #? search them together in one declared order.
      packageSets =
        listToAttrs (
          map (name: {
            inherit name;
            value = (import sources.${name}.path) {inherit pkgs;};
          })
          pkgSets
        )
        // {inherit pkgs;};

      #? These entry points are *curried*, not positional: cachyOS declares
      #? `{inputs}: pkgs: ...`, so applying them to a single argument
      #? returns a function rather than a value. The arguments are therefore
      #? applied one at a time, each in its own round.
      #?
      #? `args` names what each round receives: `pkgs` passes the package
      #? set, anything else an empty attrset, since these take no other
      #? inputs -- cachyOS needs its flake inputs at *build* time.
      loaders =
        mapAttrs (
          name: spec: let
            entry = import "${sources.${name}.path}/${spec.file}";
            rounds =
              map (set: optionalAttrs (set == "pkgs") pkgs)
              spec.args;
            supplied = foldl' id entry rounds;
          in
            supplied
        )
        pkgLoaders;

      #? Sources whose packages live in `flake.packages.<system>` rather than
      #? behind a `default.nix`.
      #?
      #? A fourth shape, alongside overlays, package-set functions and loaders.
      #? `hermes-agent` has no root `default.nix` at all, so `import path` cannot
      #? read it and the package-set route fails outright -- its outputs are
      #? only reachable through the flake interface.
      #?
      #? `configKeys` and `node-gyp` are internals of the build, not things a
      #? spec would request, so they are dropped: `resolvePackageGroups` should
      #? not be able to install a helper by accident. `default` is kept -- that
      #? is the name the alias table points `hermes` at.
      flakes =
        listToAttrs (
          map (name: {
            inherit name;
            value =
              removeAttrs
              (
                (
                  builtins.getFlake (toString sources.${name}.url)
                ).packages.${pkgs.stdenv.hostPlatform.system}
                or {}
              )
              ["configKeys" "node-gyp" "update-npm-lockfile"];
          })
          pkgFlakes
        );
    };
  in
    #? `packageSets` is the pool list every consumer searches, so the flake
    #? outputs join it here rather than staying in their own key -- otherwise a
    #? caller reading `packageSets` sees zen but not hermes, and the alias table
    #? points at a pool nobody looked in.
    resolved
    // {
      packageSets = resolved.packageSets // resolved.flakes;
      inherit pkgs;
    };

  /**
  Build a single shell-ready command string from a package specification.

  The argument may be either a string or an attrset.  When it is an
  attrset the following optional fields are recognised:

    :
    `name`         attribute name (required for attrsets)

    :
    `pkg`          Nixpkgs attribute path (dotted). Defaults to `name`.

    :
    `stem`         binary name inside `$out/bin`. Defaults to `name`.

    :
    `arguments`    extra arguments (shell-escaped).

    :
    `pkgs`         already-evaluated package set (highest priority).

    :
    `system`       system string for `mkNixPkgs` when `pkgs` is absent.

    :
    `host`         host attrset for `mkNixPkgs` when `pkgs` is absent.


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

    pkgs = spec.pkgs or mkNixPkgs {
      system = spec.system or null;
      host = spec.host   or null;
    };

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
  #? the fetched package sets and loaders -- `mkSets` already folds them into
  #? one attrset beside `pkgs`, so this is a second pool rather than N.
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
    #? Additional pools, searched after `pkgs`, each an attrset of
    #? derivations. A list, not an attrset: order is the search order, and
    #? `mkSets` returns the pools keyed by source for exactly that reason --
    #? `attrValues` turns them into the order to try.
    extra ? [],
    aliasOf ? name: null,
    #? Treat an unsatisfiable name as fatal rather than a warning. Off by
    #? default, because a principal's declarations are wishes.
    strict ? false,
  }: let
    expanded = unique (expandNames {inherit groups names;});

    pools = [pkgs] ++ extra;

    poolOf = name:
      let
        found = builtins.filter (pool: pool ? ${name}) pools;
      in
        if found == []
        then null
        else builtins.elemAt found 0;

    resolvedName = name: let
      entry = aliasOf name;
    in
      if entry != null
      then entry.name
      else name;

    derivationOf = name: let
      candidate = resolvedName name;
      pool = poolOf candidate;
    in
      if pool == null
      then
        throw ''
          ${context}: package '${name}' was not found.
          Looked for '${resolvedName name}' in nixpkgs and ${toString (builtins.length extra)} fetched package set(s).
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
    quoteAll = names: concatStringsSep ", " (map (n: "'${n}'") names);

    satisfied = builtins.filter (name: poolOf (resolvedName name) != null) expanded;

    missing = builtins.filter (name: poolOf (resolvedName name) == null) expanded;

    missingWarning =
      if missing == []
      then null
      else ''
        ${context}: wanted ${quoteAll missing}, which is in neither nixpkgs nor
        ${toString (builtins.length extra)} fetched package set(s). Dropping them.
      '';
    #? The result, shared by both policies so the shape cannot differ between
    #? them -- a caller reads `.packages` either way.
    result = {
      inherit satisfied missing;
      warnings = if missing == [] then [] else [missingWarning];
      packages = map derivationOf satisfied;
    };
  in
    if missing != [] && strict
    then
      throw ''
        ${context}: no package for ${quoteAll missing}.
        Looked in nixpkgs and ${toString (builtins.length extra)} fetched package set(s).
        This name was required, so the build cannot continue -- either drop it
        from the spec or add it to the alias table.
      ''
    else result;
in {
  inherit
    mkBin
    mkBins
    mkBins'
    mkSets
    expandNames
    resolvePackage
    resolvePackageGroups
    ;
}
