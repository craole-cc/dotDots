{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) DOTS;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    listOf
    package
    attrs
    either
    str
    ;

  base = "interface";
  mod = "xfce";
  cfg = DOTS.${base}.${mod};

  inherit (DOTS.${base}) manager;
in
{
  options.DOTS.${base}.${mod} = {
    enable = mkEnableOption mod // {
      default = manager == mod;
    };
    packages = mkOption {
      description = "List of {{mod}}-specific packages";
      default =
        with pkgs;
        [
          orca
          file-roller
          gnome-disk-utility
          zuki-themes
        ]
        ++ (with xfce; [
          catfish
          # gigolo
          # orage
          # xfburn
          # xfce4-appfinder
          xfce4-clipman-plugin
          xfce4-cpugraph-plugin
          xfce4-dict
          xfce4-fsguard-plugin
          # xfce4-genmon-plugin
          xfce4-netload-plugin
          xfce4-panel
          xfce4-pulseaudio-plugin
          xfce4-systemload-plugin
          xfce4-weather-plugin
          # xfce4-whiskermenu-plugin
          xfce4-xkb-plugin
          # xfdashboard
        ]);
      type = listOf package;
    };
    programs = mkOption {
      description = "List of {{mod}}-specific programs";
      default = {
        thunar = {
          enable = true;
          plugins = with pkgs.xfce; [
            thunar-archive-plugin
            thunar-media-tags-plugin
            thunar-volman
          ];
        };
      };
      type = attrs;
    };
    theme = {
      greeter = mkOption {
        description = "The lightdm greeter theme";
        default = "Zukitre-dark";
        type = either package str;
      };
    };
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
        displayManager = {
          lightdm = {
            enable = true;
            greeters.slick = {
              enable = true;
              theme.name = cfg.theme.greeter;
            };
          };
          sessionCommands = ''
            test -f ~/.xinitrc && . ~/.xinitrc
          '';
        };
        excludePackages = [ pkgs.xterm ];
      };
    };
    programs = cfg.programs;
    environment.systemPackages = cfg.packages;

  };
}
