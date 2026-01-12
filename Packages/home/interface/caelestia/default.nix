{
  lib,
  pkgs,
  host,
  config,
  user,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.strings) hasPrefix;

  name = "caelestia";
  kind = "bar";
  city = host.localization.city or "Mandeville, Jamaica";
  fonts = user.interface.style.fonts or {};
  vimKeybinds = user.interface.keyboard.vimKeybinds or false;
  paths = let
    homeDir = config.home.homeDirectory;
    mkPath = key: default: let
      path = user.paths.${key} or default;
    in
      if path != {} && !(hasPrefix "/" path) && !(hasPrefix "root:" path)
      then "${homeDir}/${path}"
      else path;
  in {
    wallpapers = mkPath "wallpapers" "${homeDir}/Pictures/Wallpapers";
    userAvatar = mkPath "avatar" "root:/assets/kurukuru.gif";
    mediaAvatar = mkPath "mediaAvatar" "root:/assets/bongocat.gif";
  };
  programs.${name} = mkMerge [
    (import ./cli {})
    (import ./settings {inherit city fonts mkMerge paths vimKeybinds;})
  ];
  packages = with pkgs; [
    aubio
    brightnessctl
    ddcutil
    glibc
    libgcc
    cava
    lm_sensors
    thunar
  ];

  cfg = {
    inherit name kind programs;
    enable = true;
    home = {inherit packages;};
  };
in {
  config = mkIf cfg.enable (mkMerge [
    {inherit (cfg) programs home;}
    (import ./hyprland.nix {inherit lib config;})
  ]);
}
