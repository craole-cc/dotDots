{
  config,
  host,
  lib,
  ...
}: let
  dom = "dots";
  mod = "interface";
  cfg = config.${dom}.${mod};
  sys = host.${mod} or {};

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) nullOr str;
in {
  imports = [
    ./environment
    # ./desktop
    # ./wayland.nix
    # ./window-manager
    # ./fonts.nix
    # ./style.nix
  ];

  options.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    wm = mkOption {
      description = "Window manager";
      default = null;
      type = nullOr str;
    };
    de = mkOption {
      description = "Desktop environment";
      default = null;
      type = nullOr str;
    };
    dm = mkOption {
      description = "Display manager";
      default = null;
      type = nullOr str;
    };
    dp = mkOption {
      description = "Display protocol";
      default = "wayland";
      type = str;
    };
    bar = mkOption {
      description = "Status bar";
      default = null;
      type = nullOr str;
    };
  };

  config = mkIf cfg.enable {
    ${dom}.${mod} = {
      wm = sys.windowManager        or cfg.wm;
      de = sys.desktopEnvironment   or cfg.de;
      dm = sys.displayManager       or cfg.dm;
      dp = sys.displayProtocol      or cfg.dp;
      bar = sys.bar                 or cfg.bar;
    };
  };
}
