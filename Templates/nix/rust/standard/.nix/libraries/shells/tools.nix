{lib, ...}: let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) concatMap flatten;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) mkStyledOutput;
  inherit (lib.shells) common web editor;
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
    packages = flatten (concatMap (g:
      attrValues (g.packages or {})
      ++ attrValues (g.scripts or {}))
    (attrValues groups));
  };
}
