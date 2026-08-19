args: let
  inherit (args.lix.attrsets.access) attrValues;
  inherit (import ./packages.nix args) binaries;

  treefmt =
    import ./modules
    (args // {inherit binaries;});

  formatter = treefmt.wrapper;
  packages = attrValues treefmt.programs;
in
  treefmt
  // {
    inherit formatter;
    checks.formatting = treefmt.check args.flake.path;
    formatters = packages ++ [formatter];
  }
