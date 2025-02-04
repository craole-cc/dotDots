{ osConfig, pkgs, ... }:
{
  imports = [
    # ./icons.nix
    ./settings.nix
  ];
  services.dunst = {
    enable = true;
    configFile = osConfig.dots.paths.qbx.conf.dunst + "/dunstrc";
  };
  home.packages = with pkgs; [
    jq
    libnotify
  ];
}
