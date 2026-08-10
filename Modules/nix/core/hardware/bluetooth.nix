{
  config,
  pkgs,
  host,
  lib,
  top,
  lix,
  ...
}: let
  dom = "hardware";
  mod = "bluetooth";
  cfg = config.${top}.inputs.${dom}.${mod};

  inherit (lib.modules) mkMerge;
  inherit (lix.lists.construction) optionals;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lix.types.primitives) bool package str;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.attrsets.resolution) packages;

  payload = {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };
    services = {inherit (cfg) blueman;};
    environment.systemPackages = packages {
      inherit pkgs;
      targets = cfg.packages;
    };
  };
  inherit (lix.modules.core._) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = host.hardware.hasBluetooth;};
    powerOnBoot = mkOption {
      description = "Power bluetooth on boot";
      default = cfg.enable;
      type = bool;
    };
    packages = mkOption {
      description = "Extra bluetooth packages";
      default = optionals cfg.enable ["bluez"];
      type = listOf (either str package);
    };
    blueman = {
      enable = mkOption {
        description = "Enable blueman service";
        default = cfg.enable;
        type = bool;
      };
    };
  };

  config = mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
