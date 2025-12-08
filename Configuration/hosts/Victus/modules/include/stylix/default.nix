{ inputs, ... }:
{
  imports = [
    inputs.styleManager.nixosModules.stylix
    ./fonts.nix
    ./scheme.nix
  ];
  stylix = {
    enable = true;
    enableReleaseChecks = false;
  };
}
