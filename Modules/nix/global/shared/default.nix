args: let
  lib = import ./lib args;
  pkgs = import ./packages.nix args;
  formatting = import ./fmt (args // lib // pkgs);
in
  lib // pkgs // formatting
