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
  inherit (lix.strings.predicates) contains;
  inherit (lib.modules) mkIf mkForce;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool int str;

  kernelRequested = host.packages.kernel or null;
  isChaotic =
    kernelRequested
    != null
    && (
      contains "cachyos" kernelRequested
      || hasAttr kernelRequested pkgs
    );
in {
  options.${top}.${dom}.${mod} = {
    enable = mkEnableOption mod // {default = true;};
    stateVersion = mkOption {
      description = "NixOS state version";
      default = "25.11";
      type = str;
    };
    maxJobs = mkOption {
      description = "Max Nix build jobs";
      default = "auto";
      type = str;
    };
    extraSubstituters = mkOption {
      description = "Extra binary caches";
      default = [];
      type = types.listOf str;
    };
    extraTrustedKeys = mkOption {
      description = "Extra trusted public keys";
      default = [];
      type = types.listOf str;
    };
  };

  config = mkIf cfg.enable {
    ${top}.${dom}.${mod} = {
      stateVersion = host.stateVersion          or cfg.stateVersion;
      maxJobs = host.specs.cpu.cores       or cfg.maxJobs;
      extraSubstituters = optionals isChaotic ["https://nyx.chaotic.cx/"];
      extraTrustedKeys = optionals isChaotic ["nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc="];
    };

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
