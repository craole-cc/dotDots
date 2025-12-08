{lib ? import <nixpkgs/lib>, ...}: let
  libraries = import ./libraries {inherit lib; name = "lix";};
  inherit (libraries) lix;
  api = import ./api {
    inherit lix;
    inherit (lix) lib;
  };
in {inherit lix api;}
