{lix, ...}: let
  inherit (lix.modules) importHosts;
in {
  hosts = importHosts ./hosts;
}
