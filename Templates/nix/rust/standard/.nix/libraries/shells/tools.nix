{lib, ...}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap flatten;
  inherit (lib.packages) mkPkgs;
  # inherit (lib.shells) common editor;
  # anchor = lib.shells.setMarker {};
in {
  mkTools = {
    pkgs ? mkPkgs {},
    channel ? "nightly",
    includeDatabase ? false,
    includeRust ? false,
    includeExtras ? false,
    includeWeb ? false,
    withEditor ? null,
  }: let
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
  };
}
