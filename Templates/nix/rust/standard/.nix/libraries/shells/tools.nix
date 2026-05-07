{lib, ...}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap flatten;
  inherit (lib.packages) mkPkgs;
  inherit (lib.shells) common editor;
in {
  mkTools = {
    pkgs ? mkPkgs {},
    includeExtras ? false,
    includeWeb ? false,
    withEditor ? null,
  }: let
    anchor = lib.shells.setMarker {};
    project = baseNameOf anchor;

    groups =
      (common.mkGroups {
        inherit pkgs includeExtras includeWeb;
      })
      // (editor.mkGroups {
        inherit pkgs project withEditor;
      });
  in {
    # inherit style;
    packages = let
      # gs = attrValues groups;
      # _ = builtins.trace (builtins.toJSON (map (g: builtins.attrNames (g.scripts or {})) gs)) null;
    in
      flatten (concatMap (g:
        attrValues (g.packages or {})
        ++ attrValues (g.scripts or {}))
      (attrValues groups));
  };
}
