{lib, ...}: let
  inherit (lib.attrsets) hasAttr;
  inherit (lib.modules) mkForce;
  inherit (lib.strings) hasInfix optionalString;

  mkNix = {
    host,
    pkgs,
    ...
  }: let
    kernelRequested = host.packages.kernel or null;
    isCachy = kernelRequested != null && (hasInfix "cachyos" kernelRequested);
    isChaotic = kernelRequested != null && hasAttr kernelRequested pkgs;

    nyxSub = optionalString (isCachy || isChaotic) "https://nyx.chaotic.cx/";
    nyxKey = optionalString (isCachy || isChaotic) "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
    # cachySub = lib.strings.optionalString isCachy "https://drakon64-nixos-cachyos-kernel.cachix.org/";
    # cachyKey = lib.strings.optionalString isCachy "drakon64-nixos-cachyos-kernel.cachix.org-1:J3gjZ9N6S05pyLA/P0M5y7jXpSxO/i0rshrieQJi5D0=";
  in {
    system = {
      stateVersion = host.stateVersion or "25.11";
    };

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        max-jobs = host.specs.cpu.cores or "auto";
        trusted-users = ["@wheel"];
        substituters = [
          "${nyxSub}"
          # "${cachySub}"
        ];
        trusted-public-keys = [
          "${nyxKey}"
          # "${cachyKey}"
        ];
      };
    };

    systemd.services = {
      nix-daemon.serviceConfig.LimitNOFILE = mkForce "65536 1048576";
    };
  };

  mkClean = {host, ...}: {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 3d --keep 5";
      };
      flake = host.paths.dots;
    };
  };

  exports = {inherit mkNix mkClean;};
in
  exports // {_rootAliases = exports;}
