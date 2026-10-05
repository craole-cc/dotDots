{lib ? import <nixpkgs/lib>, ...}: let
  args = rec {
    lix = import ./libraries {inherit lib;};
    api = import ./api;
    host = lix.types.host.mkHost api;
    context = import ./middleware {inherit lix host;};
    tests = import ./tests args;
    inherit (context) packages;
  };
in
  args
  // {
    inherit (import ./modules) imports;
    _module = {inherit args;};
  }
