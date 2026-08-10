{
  config,
  lix,
  top,
  ...
}: let
  dom = "hardware";
  mod = "display";
  cfg = config.${top}.inputs.${dom}.${mod};

  iface = config.${top}.inputs.interface;
  isWayland = iface.displayProtocol == "wayland";

  inherit (lix.lists.construction) optionals;
  inherit (lix.modules.construction) mkDefault mkIf mkMerge;
  inherit (lix.modules.core._) mkStaged;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.strings.predicates) versionAtLeast;
  inherit (lix.types.primitives) bool str;

  nvidiaVersionAtLeast = version:
    versionAtLeast config.hardware.nvidia.package.version version;

  payload = {
    services.xserver = mkIf (!isWayland) {
      enable = true;
      videoDrivers = optionals cfg.nvidia.enable ["nvidia"];
      xkb = {
        layout = cfg.xkbLayout;
        variant = cfg.xkbVariant;
      };
    };
    programs.xwayland.enable = isWayland;
    hardware.nvidia = with cfg.nvidia; {
      open = mkDefault open;
      gsp.enable = mkDefault gsp.enable;
      powerManagement.kernelSuspendNotifier = mkDefault powerManagement.kernelSuspendNotifier;
    };
    xdg.portal.xdgOpenUsePortal = true;
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
        default = config.hardware.nvidia.modesetting.enable or false;
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
    inherit top payload;
    condition = cfg.enable;
  });
}
