args: let
  packages = import ./packages.nix args;
  formatting = import ./fmt.nix (args // packages);
in
  packages // formatting
