{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  tree,
  ...
}: let
  dom = "system";
  mod = "nix";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) either int str;
  inherit (lix.modules.core.software) mkNix mkMaintenance;
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};

    stateVersion = mkOption {
      description = "NixOS state version";
      default = host.stateVersion or "25.11";
      type = str;
    };

    maxJobs = mkOption {
      description = "Max Nix build jobs";
      default = host.specs.cpu.cores or "auto";
      type = either int str;
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      (mkNix {inherit host pkgs tree;})
      (mkMaintenance {inherit host;})
      {
        nix.settings.max-jobs = cfg.maxJobs;
        system.stateVersion = cfg.stateVersion;
      }
    ]
  );
}
