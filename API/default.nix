{lix, ...}: let
  inherit (lix.filesystem.importers) importAttrset;
in {
  hosts = importAttrset ./hosts;
  users = importAttrset ./users;
}
