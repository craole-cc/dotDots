{
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lix.filesystem.importers) importAttrset;
  inherit (lix.modules) recursiveUpdate;

  hosts = mapAttrs (_: recursiveUpdate) (importAttrset ./hosts);
  users = mapAttrs (_: recursiveUpdate) (importAttrset ./users);
in {inherit hosts users;}
