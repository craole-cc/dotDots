lib: let
  default =
    {
      class = "nixos";
      stateVersion = null;
      system = null;
      name = null;
      id = null;
      description = null;
    }
    // (import ./applications.nix)
    // (import ./functionalities.nix)
    // (import ./interface.nix)
    // (import ./localization.nix)
    // (import ./packages.nix)
    // (import ./paths.nix)
    // (import ./specs.nix)
    // {principals = [];};
in
  (import ./lib.nix (lib // {inherit default;}))
  // {host = default;}
