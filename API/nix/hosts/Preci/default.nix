{lib ? import <nixpkgs/lib>, ...}: let
  lix = import ./libraries {inherit lib;};
  specs = import ./specs;
  host = lix.schemas.host.mkHost specs;
  context = import ./context {inherit lix host;};
  modules = import ./modules {inherit lix;};
in {
  inherit (modules) imports;
  _module.args = {inherit lix host context specs;};
}
