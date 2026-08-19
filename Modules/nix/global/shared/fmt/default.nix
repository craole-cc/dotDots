args: let
  inherit (import ./packages.nix args) packages binaries;

  treefmt =
    import ./modules
    (args // {inherit binaries;});
in {
  inherit (treefmt) apps checks formatter;
  formatters = packages ++ [treefmt.formatter];
}
