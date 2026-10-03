{
  lib ? import <nixpkgs/lib>,
  lix ? import ./libraries {inherit lib;},
  specs ? lix.schemas.host.mkHost (import ./specs),
  context ? import ./context {inherit lix specs;},
  modules ? (import ./modules {inherit lix;}),
  ...
}: {
  imports = [modules];
  _module.args = {inherit lix specs context;};
}
