# TODO Collab: We never see services or environment in the stage
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
  cfg = config.${top}.resolved.${dom}.${mod};
  hw = host.hardware;

  inherit (lib.modules) mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lix.attrsets.resolution) packages;
  inherit (lix.lists.construction) optionals;
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.types.primitives) bool package str;

  resolvedPackages = packages {
    inherit pkgs;
    targets = cfg.packages;
  };
in {
  options.${top}.resolved.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = hw.hasBluetooth;};
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
  config = mkMerge ((mkStaged {
      inherit top;
      condition = cfg.enable;
      payload = {
        hardware.bluetooth = {
          enable = true;
          inherit (cfg) powerOnBoot;
        };
        services = {inherit (cfg) blueman;};
        environment.systemPackages = resolvedPackages;
      };
    }) ++ [
    {
      ${top}.outputs = lib.mkIf cfg.enable {hardware.bluetooth.packages = resolvedPackages;};
    }
  ]);
}
