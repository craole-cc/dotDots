{
  config,
  lib,
  lix,
  top,
  ...
}: let
  dom = "hardware";
  mod = "display";
  cfg = config.${top}.inputs.${dom}.${mod};

  iface = config.${top}.inputs.interface;
  isWayland = iface.displayProtocol == "wayland";
  nvidiaEnabled = config.hardware.nvidia.modesetting.enable or false;

  inherit (lix.modules.construction) mkDefault mkIf mkMerge;
  inherit (lix.strings.predicates) versionAtLeast;
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool str;

  nvidiaVersionAtLeast = version:
    versionAtLeast config.hardware.nvidia.package.version version;

  payload = {
    services.xserver = mkIf (!isWayland) {
      enable = true;
      videoDrivers =
        if cfg.nvidia.enable
        then ["nvidia"]
        else [];
      xkb = {
        layout = cfg.xkbLayout;
        variant = cfg.xkbVariant;
      };
    };
    programs.xwayland.enable = isWayland;
    hardware.nvidia = {
      open = mkDefault cfg.nvidia.open;
      gsp.enable = mkDefault cfg.nvidia.gsp.enable;
      powerManagement.kernelSuspendNotifier =
        mkDefault cfg.nvidia.powerManagement.kernelSuspendNotifier;
    };
    xdg.portal.xdgOpenUsePortal = true;
  };
  outputPayload = payload // {
    hardware.nvidia = {
      open = cfg.nvidia.open;
      gsp.enable = cfg.nvidia.gsp.enable;
      powerManagement.kernelSuspendNotifier =
        cfg.nvidia.powerManagement.kernelSuspendNotifier;
    };
  };
in {
  options.${top}.inputs.${dom}.${mod} = {
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
    nvidia = {
      enable = mkOption {
        description = "Enable nvidia video driver";
        default = nvidiaEnabled;
        type = bool;
      };
      open = mkOption {
        description = "Enable the open nvidia kernel module";
        default = cfg.nvidia.enable;
        type = bool;
      };
      gsp.enable = mkOption {
        description = "Enable the nvidia GPU System Processor";
        default = cfg.nvidia.open || nvidiaVersionAtLeast "555";
        type = bool;
      };
      powerManagement.kernelSuspendNotifier = mkOption {
        description = "Enable the nvidia kernel suspend notifier";
        default = cfg.nvidia.open && nvidiaVersionAtLeast "595";
        type = bool;
      };
    };
  };

  config = mkMerge (mkStaged {
    inherit top payload outputPayload;
    condition = cfg.enable;
  });
}
