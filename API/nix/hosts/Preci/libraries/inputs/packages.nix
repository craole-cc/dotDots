{
  lix,
  modules,
  ...
}: let
  inherit (lix.attrsets) attrByPath listToAttrs;
  inherit (lix.lists) concatMap elem toList unique;
  inherit (lix.strings) concatStringsSep escapeShellArg isString mkPath splitString;
  inherit (modules) mkNixPkgs;

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
    arguments = spec.arguments or [];

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
      ++ map escapeShellArg arguments
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
          pkgs = value.pkgs   or pkgs;
          host = value.host   or host;
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
    expandNames
    resolvePackage
    resolvePackageGroups
    ;
}
