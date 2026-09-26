{
  lix,
  system,
  inputs ? lix.flake.inputs or {},
  ...
}: let
  sources = import ./sources.nix {inherit lix;};
  overlays = import ./overlays.nix {inherit lix inputs sources;};
  modules = import ./modules.nix {
    inherit
      lix
      system
      inputs
      sources
      overlays
      ;
  };
  imports = with modules; [
    home-manager
    nix-index
    catppuccin
  ];
in {inherit modules sources overlays imports;}
