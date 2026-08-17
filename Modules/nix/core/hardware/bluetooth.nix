{
  config,
  pkgs,
  host,
  lix,
  ...
}: let
  context = mkContext {
    inherit config;
    dom = "hardware";
    mod = "bluetooth";
  };
  inherit (context) cfg;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkEnable mkOption;
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
    inherit context;
    options = {
      enable = mkEnable {
        inherit context;
        condition = host.hardware.hasBluetooth;
      };
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
