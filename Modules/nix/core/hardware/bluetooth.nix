{
  config,
  pkgs,
  host,
  top,
  lix,
  ...
}: let
  dom = "hardware";
  mod = "bluetooth";
  cfg = config.${top}.resolved.${dom}.${mod}.explicit;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.options.construction) mkEnableOption mkOption;
  inherit (lix.attrsets.resolution) packages;
  inherit (lix.lists.construction) optionals;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.types.primitives) bool package str;

  defaultPackages = packages {
    inherit pkgs;
    targets = optionals cfg.enable ["bluez"];
  };
  resolvedPackages = packages {
    inherit pkgs;
    targets = cfg.packages;
  };
in
  mkConfig {
    inherit config top dom mod;
    options = {
      enable = mkEnableOption mod // {default = host.hardware.hasBluetooth;};
      powerOnBoot = mkOption {
        description = "Power bluetooth on boot";
        default = cfg.enable;
        type = bool;
      };
      packages = mkOption {
        description = "Extra bluetooth packages";
        default = defaultPackages;
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
    outputs = {
      hardware.bluetooth = {
        enable = true;
        inherit (cfg) powerOnBoot;
      };
      services = {inherit (cfg) blueman;};
      environment.systemPackages = resolvedPackages;
    };
  }
# */
