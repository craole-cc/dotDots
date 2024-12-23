{
  config,specialArgs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  enable =specialArgs.host.desktop=="plasma" ||
    (with config.services;
    desktopManager.plasma6.enable || displayManager.defaultSession == "plasma");
  excludePackages = with pkgs; [ kate ];
  includePackages =
    with pkgs;
    [ kde-gruvbox ]
    ++ (with kdePackages; [
      # full
      koi
      kalm
      yakuake
    ]);
in
{
  config = mkIf enable {
    environment = {
      plasma5 = { inherit excludePackages; };
      plasma6 = { inherit excludePackages; };
      systemPackages = includePackages;
    };
  };
}
