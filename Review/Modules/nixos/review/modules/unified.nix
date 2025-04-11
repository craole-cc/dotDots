{ inputs, ... }:
{
  imports = with inputs.nixos-unified.flakeModules; [
    default
    autoWire
  ];
  perSystem =
    { self', ... }:
    {
      packages.default = self'.packages.activate;

      # Flake inputs we want to update periodically
      # Run: `nix run .#update`.
      nixos-unified = {
        primary-inputs = [
          "nixpkgs"
          "home-manager"
          "nix-darwin"
          "nixos-unified"
          "nix-index-database"
          "nixvim"
          "omnix"
        ];
      };
    };
}
