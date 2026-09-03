{
  config,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "hardware";
    mod = "display";
  };
  inherit (context) cfg;

  inherit (lix.modules.construction) mkConfig mkContext mkDefault mkIf;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.predicates) versionAtLeast;
  inherit (lix.types.primitives) bool str;

  # Safe protocol resolution with fallback chain
  iface = config.${context.top}.resolved.interface or {};
  session = config.interface.common.session or {};
  protocol = iface.protocol or iface.displayProtocol or session.protocol or "wayland";
  isWayland = protocol == "wayland";

  nvidiaEnabled = config.hardware.nvidia.modesetting.enable or false;
  nvidiaVersionAtLeast = version:
    versionAtLeast (config.hardware.nvidia.package.version or "0") version;
in
  mkConfig {
    inherit context;
    options = {
      enable = mkEnable {
        description = "Display server and GPU driver configuration";
        condition = true;
      };
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
    outputs = {
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
      xdg.portal.xdgOpenUsePortal = true;

      hardware.nvidia = mkIf cfg.enable {
        open = mkDefault cfg.nvidia.open;
        gsp.enable = mkDefault cfg.nvidia.gsp.enable;
        powerManagement.kernelSuspendNotifier = mkDefault cfg.nvidia.powerManagement.kernelSuspendNotifier;
      };
    };
  }