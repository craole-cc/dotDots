{
  lix,
  modules,
  packageSets ? [],
  packageLoaders ? {},
  ...
}: let
  inherit (lix) inputs;
  inherit (lix.attrsets) attrByPath listToAttrs mapAttrs optionalAttrs;
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
  }: let
    resolved = {
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
    };
  in
    resolved // {inherit pkgs;};

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

  resolvePackageGroups = {
    pkgs,
    groups,
    names,
    context,
  }: let
    expanded = unique (expandNames {inherit groups names;});
  in
    map (
      name:
        pkgs.${name} or (throw "${context}: package '${name}' was not found in nixpkgs")
    )
    expanded;
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
