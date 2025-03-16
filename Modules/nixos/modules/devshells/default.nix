{self, ...}: {
  perSystem = perSystem @ {
    config,
    lib,
    pkgs,
    ...
  }:
    {
      devshells =
        let
          shells = with paths.devshells; {
            dots = import dots.nix { inherit pkgs paths; };
            media = import media.nix { inherit pkgs paths; };
          };
        in
        with shells;
        {
          default = dots;
          inherit dots media;
        };
      # treefmt = import ./Modules/nixos/modules/treefmt.nix { inherit pkgs; };
    };
}
