{ config, pkgs, ... }:
let
  plasmaEnabled =
    with config.services;
    desktopManager.plasma6.enable || displayManager.defaultSession == "plasma";
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
  environment =
    if plasmaEnabled then
      {
        plasma5 = { inherit excludePackages; };
        plasma6 = { inherit excludePackages; };
        systemPackages = includePackages;
      }
    else
      { };
}
