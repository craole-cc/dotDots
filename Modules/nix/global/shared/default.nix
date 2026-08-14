args: let
  lib = import ./lib.nix args;
  formatting = import ./fmt.nix (args // lib);
in
  lib // formatting
