args: let
  lib = import ./lib args;
  formatting = import ./fmt (args // lib);
in
  lib
  // formatting
