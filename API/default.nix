{lix, ...}: let
  inherit (lix.std.attrsets) mapAttrs;
  inherit (lix.filesystem.importers) importAttrset;
  inherit (lix.modules) recursiveUpdate;
in {
  hosts = mapAttrs (_: recursiveUpdate) (importAttrset ./hosts);
  users = mapAttrs (_: recursiveUpdate) (importAttrset ./users);
}
