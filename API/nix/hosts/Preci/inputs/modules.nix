{
  lix,
  system,
  inputs ? lix.flake.inputs or {},
  sources ? import ./sources.nix {inherit lix inputs;},
  overlays ? import ./overlays.nix {inherit lix inputs sources;},
  ...
}: let
  inherit (lix.fetchers) fetchModule;
  resolveModule = args: fetchModule (args // {inherit inputs sources;});
in {
  # nixpkgs = let
  #   args = {
  #     inherit system;
  #     config = {allowUnfree = true;};
  #     overlays = [(import overlays.rust-overlay)];
  #   };
  # in
  #   import sources.nixpkgs (
  #     if sources.nixpkgs.fromFlake
  #     then args
  #     else removeAttrs args ["system"] # TODO: Confirm that system is not required
  #   );

  nixpkgs = import sources.nixpkgs {
    inherit system;
    config = {allowUnfree = true;};
    overlays = [(import overlays.rust-overlay)];
  };

  home-manager = resolveModule {
    name = "home-manager";
    path = "nixos";
  };

  dots = sources.dots;

  catppuccin = resolveModule {
    name = "catppuccin";
    path = "modules/nixos";
  };

  nix-index = resolveModule {
    name = "nix-index";
    path = "nixos-module.nix";
  };
}
