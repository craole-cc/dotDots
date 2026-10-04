{lib ? import <nixpkgs/lib>, ...}: let
  lix = import ./libraries {inherit lib;};
  api = import ./api;
  host = lix.types.host.mkHost api;
  context = import ./context {inherit lix host;};
  modules = import ./modules;
in {
  imports = modules.imports;
  _module.args = {inherit lix host context api;};
}
