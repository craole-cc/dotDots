{lib, ...}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap flatten foldl';
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatNonEmpty;
  # inherit (lib.shells) common editor;
  # anchor = lib.shells.setMarker {};
in {
  mkTools = {
    pkgs ? mkPkgs {},
    variant ? {},
  }: let
    inherit (variant) base rust web database editor;
    groups = {};
    # groups =
    #   (common.mkGroups {inherit pkgs includeExtras includeWeb;})
    #   // (editor.mkGroups {
    #     inherit pkgs withEditor;
    #     name = baseNameOf anchor;
    #   });
  in {
    packages = flatten (concatMap (g:
      attrValues (g.packages or {})
      ++ attrValues (g.scripts or {}))
    (attrValues groups));
    env = foldl' (acc: g: acc // (g.env or {})) {} (attrValues groups);
    shellHook = concatNonEmpty {
      separator = "\n";
      parts = attrValues (groups.shellHooks or {});
    };
  };
}
