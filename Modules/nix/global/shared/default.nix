args: let
  lib = import ./lib.nix args;
  formatting = import ./fmt (args // lib);
in
  lib // formatting
