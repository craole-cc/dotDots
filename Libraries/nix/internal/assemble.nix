{
  lib',
  customLib,
  path,
}: let
  inherit (lib'.attrsets) attrNames filterAttrs genAttrs recursiveUpdate;
  inherit (lib'.lists) filter;
  inherit (lib'.filesystem) readDir;
  inherit (lib'.strings) hasSuffix removeSuffix;

  libDir = ./lib;
  libImports = import libDir;
  init = f: f {lib = lib';};

  libs = let
    # Read dir, filter to .nix files, exclude default.nix, strip extension
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
            (readDir libDir)
          )
        )
      );
  in
    genAttrs names (name: init libImports.${name});

  # Pass 1: Base libs available to all scanned lib functions via self
  withLibs = customLib.extend (_: prev: recursiveUpdate libs prev);

  # Pass 2: Metadata only
  lix = withLibs.extend (
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
