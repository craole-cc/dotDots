{
  lib,
  handleCollisions,
  library,
  paths,
  rootAliases,
}:
let
  inherit (lib.attrsets)
    attrNames
    filterAttrs
    genAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) filter;
  inherit (lib.filesystem) readDir;
  inherit (lib.strings) hasSuffix removeSuffix;

  lib' =
    let
      base =
        let
          raw = paths.libraries + "/imports";
          set = import raw;
          init =
            f:
            f {
              inherit lib;
              flatten = false;
            };
          names = filter (name: name != "default") (
            map (f: removeSuffix ".nix" f) (
              attrNames (filterAttrs (n: t: t == "regular" && hasSuffix ".nix" n && n != "default.nix") (readDir raw))
            )
          );
        in
        genAttrs names (name: init set.${name});
    in
    library.extend (_: prev: recursiveUpdate base prev);

  lix = lib'.extend (
    _: prev:
    recursiveUpdate prev {
      inherit (paths) src;
      inherit lib;
    }
  );
  base = removeAttrs lix [
    "__rootAliases"
    "__unfix__"
    "unfix"
    "extend"
  ];
  aliases = lix.__rootAliases or { };
  withAliases =
    if !rootAliases then
      base
    else
      handleCollisions {
        inherit base;
        overrides = aliases;
        msg = "Root aliases collide with modules";
      };
in
withAliases // { extend = f: lix.extend f; }
