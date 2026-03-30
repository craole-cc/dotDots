{
  lib',
  customLib,
  path,
}: let
  inherit (lib'.attrsets) attrNames filterAttrs genAttrs recursiveUpdate;
  inherit (lib'.lists) filter;
  inherit (lib'.filesystem) readDir;
  inherit (lib'.strings) hasSuffix removeSuffix;

  lib = let
    base = let
      raw = ./base;
      set = import raw;
      init = f:
        f {
          lib = lib';
          flatten = false;
        };
      names =
        filter
        (name: name != "default")
        (
          map
          (f: removeSuffix ".nix" f)
          (
            attrNames
            (
              filterAttrs
              (n: t: t == "regular" && hasSuffix ".nix" n && n != "default.nix")
              (readDir raw)
            )
          )
        );
    in
      genAttrs names (name: init set.${name});
  in
    customLib.extend (_: prev: recursiveUpdate base prev);

  lix = lib.extend (
    _: prev:
      recursiveUpdate prev {
        inherit path;
        src = path;
        lib = lib';
      }
  );
in
  removeAttrs lix ["__unfix__" "unfix" "extend"]
  // {extend = f: lix.extend f;}
