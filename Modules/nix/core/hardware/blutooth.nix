{
  config,
  host,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "hardware";
  mod = "bluetooth";
  cfg = config.${top}.${dom}.${mod};

  hw = host.hardware;

  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = hw.hasBluetooth;};
    powerOnBoot = mkOption {
      description = "Power bluetooth on boot";
      default = true;
      type = bool;
    };
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;
    };

    services.blueman.enable = true;

    environment.systemPackages = [pkgs.bluez];
  };
}
