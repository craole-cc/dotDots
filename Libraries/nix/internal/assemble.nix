{
  # collisionStrategy,
  lib,
  flake,
  library,
  # paths,
  rootAliases,
}: let
  inherit
    (lib.attrsets)
    attrNames
    filterAttrs
    genAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) elem filter;
  inherit (lib.filesystem) readDir;
  inherit (lib.strings) hasSuffix removeSuffix;
  inherit (lib.debug) trace;

  lib' = let
    base = let
      raw = ../imports;
      set = import raw;
      init = f:
        f {
          lib = lib;
          flatten = false;
        };
      names = filter (name: name != "default") (
        map (f: removeSuffix ".nix" f) (
          attrNames (
            filterAttrs (n: t: t == "regular" && hasSuffix ".nix" n && n != "default.nix") (readDir raw)
          )
        )
      );
    in
      genAttrs names (name: init set.${name});
  in
    library.extend (_: prev: recursiveUpdate base prev);

  lix = lib'.extend (
    _: prev:
      recursiveUpdate prev {
        # inherit path;
        src = path;
        lib = lib;
      }
  );
  base = removeAttrs lix [
    "__rootAliases"
    "__unfix__"
    "unfix"
    "extend"
  ];
  aliases = lix.__rootAliases or {};
  withAliases =
    if !rootAliases
    then base
    else let
      rootAliasNames = attrNames aliases;
      moduleTopLevelNames = attrNames base;
      collisions = filter (n: elem n moduleTopLevelNames) rootAliasNames;
    in
      if collisions == []
      then base // aliases
      else if collisionStrategy == "error"
      then throw "Root aliases collide with modules: ${toString collisions}"
      else if collisionStrategy == "warn"
      then trace "WARNING: Root aliases override modules for: ${toString collisions}" (base // aliases)
      else base // aliases;
in
  withAliases // {extend = f: lix.extend f;}
