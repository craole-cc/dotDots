{lib, ...}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap filter flatten foldl';
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) isNotEmpty;
in {
  mkTools = {
    pkgs ? mkPkgs {},
    variant ? {},
  }: let
    inherit (variant) base rust web database editor ai;

    groups = {};
    # groups =
    #   (common.mkGroups {inherit pkgs base rust web database ai;})
    #   // (editor.mkGroups {inherit pkgs editor;});

    groupList = attrValues groups;
  in {
    packages = flatten (
      concatMap
      (g: attrValues (g.packages or {}) ++ attrValues (g.scripts or {}))
      groupList
    );

    env = foldl' (acc: g: acc // (g.env or {})) {} groupList;

    shellHook = concatStringsSep "\n" (
      filter isNotEmpty (
        concatMap (g: attrValues (g.shellHooks or {})) groupList
      )
    );
  };
}
