{
  lib,
  handleCollisions,
  library,
  paths,
  allowAliases,
}: let
  inherit (lib.attrsets) attrNames filterAttrs genAttrs recursiveUpdate;
  inherit (lib.lists) filter;
  inherit (lib.filesystem) readDir;
  inherit (lib.strings) hasSuffix removeSuffix;

  lib' = let
    base = let
      raw = paths.core.lib.default.store + "/imports";
      set = import raw;
      init = fn:
        fn {
          inherit lib;
          flatten = false;
        };
      names = filter (name: name != "default") (
        map (f: removeSuffix ".nix" f) (
          attrNames (
            filterAttrs
            (
              name: type:
                (type == "regular")
                && (hasSuffix ".nix" name)
                && (name != "default.nix")
            )
            (readDir raw)
          )
        )
      );
    in
      genAttrs names (name: init set.${name});
  in
    library.extend (_: prev: recursiveUpdate base prev);

  custom = lib'.extend (
    _: prev:
      recursiveUpdate prev {
        # src = paths.core.src.store;
        inherit lib;
      }
  );

  base = removeAttrs custom [
    "__rootAliases"
    "__unfix__"
    "unfix"
    "extend"
  ];
in
  (
    if allowAliases
    then
      handleCollisions {
        inherit base;
        overrides = custom.__rootAliases or {};
        msg = "Root aliases collide with modules";
      }
    else base
  )
  // {extend = fn: custom.extend fn;}
