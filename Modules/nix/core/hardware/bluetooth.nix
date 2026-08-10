{
  config,
  host,
  lib,
  top,
  lix,
  ...
}: let
  dom = "hardware";
  mod = "bluetooth";
  cfg = config.${top}.inputs.${dom}.${mod};

  hw = host.hardware;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
  payload = {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };

    services.blueman.enable = true;

    # environment.systemPackages = [pkgs.bluez];
  };
  inherit (lix.modules.core._) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable =
      mkEnableOption mod
      // {
        default = hw.hasBluetooth;
      };
    powerOnBoot = mkOption {
      description = "Power bluetooth on boot";
      default = true;
      type = bool;
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
