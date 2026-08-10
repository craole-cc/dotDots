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

  hw = host.hardware;

  inherit (lib.modules) mkMerge;
  inherit (lix.lists.construction) optionals;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lix.types.primitives) bool either listOf package str;
  inherit (lix.types.predicates) isString;
  inherit (lix.attrsets.resolution) getPackage;

  getPkg = pkgs: pkg:
    if isString pkg
    then pkgs.${pkg} or (throw "Package '${pkg}' not found in pkgs")
    else pkg;
  resolvedPackages = map (getPkg pkgs) cfg.systemPackages;

  payload = {
    hardware.bluetooth = {
      enable = true;
      inherit (cfg) powerOnBoot;
    };
    services = {inherit (cfg) blueman;};
    environment = {
      systemPackages = resolvedPackages;
    };
  };
  inherit (lix.modules.core._) mkStaged;
in {
  options.${top}.inputs.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = hw.hasBluetooth;};
    powerOnBoot = mkOption {
      description = "Power bluetooth on boot";
      default = cfg.enable;
      type = bool;
    };
    systemPackages = mkOption {
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
