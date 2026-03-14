# hardware/display.nix
{
  config,
  lib,
  top,
  ...
}: let
  dom = "hardware";
  mod = "display";
  cfg = config.${top}.${dom}.${mod};

  iface = config.${top}.interface;
  isWayland = iface.dp == "wayland";
  nvidiaEnabled = config.hardware.nvidia.modesetting.enable or false;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool str;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    xkbLayout = mkOption {
      description = "XKB keyboard layout";
      default = "us";
      type = str;
    };
    xkbVariant = mkOption {
      description = "XKB keyboard variant";
      default = "";
      type = str;
    };
    nvidia = mkOption {
      description = "Enable nvidia video driver";
      default = nvidiaEnabled;
      type = bool;
    };
  };

  config = mkIf cfg.enable {
    services.xserver = mkIf (!isWayland) {
      enable = true;
      videoDrivers =
        if cfg.nvidia
        then ["nvidia"]
        else [];
      xkb = {
        layout = cfg.xkbLayout;
        variant = cfg.xkbVariant;
      };
    };

    programs.xwayland.enable = isWayland;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
    };
  };
}
