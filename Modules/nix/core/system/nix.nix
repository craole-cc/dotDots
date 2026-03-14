{
  config,
  host,
  lib,
  pkgs,
  top,
  ...
}: let
  dom = "system";
  mod = "nix";
  cfg = config.${top}.${dom}.${mod};

  inherit (lib.attrsets) hasAttr;
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkForce mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) hasInfix;
  inherit (lib.types) listOf str;

  kernelRequested = host.packages.kernel or null;
  isChaotic =
    kernelRequested
    != null
    && (hasInfix "cachyos" kernelRequested || hasAttr kernelRequested pkgs);

  chaoticSubstituters = optionals isChaotic ["https://nyx.chaotic.cx/"];
  chaoticKeys = optionals isChaotic ["nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc="];
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    stateVersion = mkOption {
      description = "NixOS state version";
      default = host.stateVersion    or "25.11";
      type = str;
    };
    maxJobs = mkOption {
      description = "Max Nix build jobs";
      default = host.specs.cpu.cores or "auto";
      type = str;
    };
    extraSubstituters = mkOption {
      description = "Extra binary caches";
      default = chaoticSubstituters;
      type = listOf str;
    };
    extraTrustedKeys = mkOption {
      description = "Extra trusted keys";
      default = chaoticKeys;
      type = listOf str;
    };
  };

  config = mkIf cfg.enable {
    system.stateVersion = cfg.stateVersion;

    nix.settings = {
      experimental-features = ["nix-command" "flakes" "pipe-operators"];
      max-jobs = cfg.maxJobs;
      trusted-users = ["@wheel"];
      substituters = cfg.extraSubstituters;
      trusted-public-keys = cfg.extraTrustedKeys;
    };

    systemd.services.nix-daemon.serviceConfig.LimitNOFILE = mkForce "65536 1048576";
  };
}
