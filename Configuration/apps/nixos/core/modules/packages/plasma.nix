{
  config,
  specialArgs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  enable =
    specialArgs.host.desktop == "plasma"
    || (
      with config.services; desktopManager.plasma6.enable || displayManager.defaultSession == "plasma"
    );
  excludePackages = with pkgs; [
    kate
    konsole
  ];
  includePackages =
    with pkgs;
    [ kde-gruvbox ]
    ++ (with kdePackages; [
      # full
      koi # TODO: Doesn't realy work
      kalm

      alpaka
      audiotube
      kaccounts-providers
      kaccounts-integration
      kapman
      kanagram
      kalarm
      kalk
      kcron
      kcolorpicker
      kcolorscheme
      kdenlive
      kio-gdrive
      plasmatube
      sddm-kcm
      solid
      kunitconversion

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
