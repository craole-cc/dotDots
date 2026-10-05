{lib ? import <nixpkgs/lib>, ...}: let
  lix = import ./libraries {inherit lib;};
  api = import ./api;
  host = lix.types.host.mkHost api;
  context = import ./context {inherit lix host;};
  modules = import ./modules;
  tests = import ./tests args;
  args = {inherit lix host context api tests;};
in
  args
  // {
    imports = modules.imports;
    _module = {inherit args;};
  }
