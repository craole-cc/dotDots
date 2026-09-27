{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  libraries = import ./libraries {inherit lib;};
  inherit (libraries) lix;

  infrastructure = import ./infrastructure (libraries
    // {
      host = lix.schemas.mkHost {
        args = import ./registry;
        registry = ./registry;
      };
    });
in {
  # imports =
  #   (with lix.modules; [
  #     home-manager
  #     nix-index
  #     catppuccin
  #   ])
  #   ++ [./outputs];

  _module.args = {
    lix = recursiveUpdate lix {inherit infrastructure;};
    inherit (libraries) lib;
  };
}
