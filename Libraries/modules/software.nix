{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (_.lists.predicates) isIn;

  mkNix = {
    host,
    inputs,
    ...
  }: {
    system = {
      stateVersion = host.stateVersion or "25.11";
    };

    nix = {
      # gc = {
      #   automatic = true;
      #   persistent = true;
      #   dates = "weekly";
      #   options = "--delete-older-than 5d";
      # };

      # optimise = {
      #   automatic = true;
      #   persistent = true;
      #   dates = "weekly";
      # };

      settings = {
        # auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
          "pipe-operators"
        ];
        max-jobs = host.specs.cpu.cores or "auto";
        # substituters = ["https://cache.nixos.org/"];
        # trusted-substituters = [
        #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        #   "https://hydra.nixos.org/"
        # ];
        trusted-users = ["root" "@wheel"];
      };

      # extraOptions = ''
      #   download-buffer-size = 524288000
      # '';
    };

    nixpkgs = let
      allowUnfree = host.packages.allowUnfree or false;
      getSystem = final: final.stdenv.hostPlatform.system;
    in {
      hostPlatform = host.system;
      config = {inherit allowUnfree;};

      overlays = [
        #~@ Stable
        (final: prev: {
          fromStable = import inputs.nixpkgs-stable {
            system = getSystem final;
            config = {inherit allowUnfree;};
          };
        })

        #~@ Unstable
        (final: prev: {
          fromUnstable = import inputs.nixpkgs-unstable {
            system = getSystem final;
            config = {inherit allowUnfree;};
          };
        })

        #~@ Flake inputs
        (final: prev: {
          fromInputs = mapAttrs (_: pkgs: pkgs.${getSystem final} or {}) inputs.packages;
        })
      ];
    };
  };

  mkLocale = {host, ...}: let
    loc = host.localization or {};
  in {
    time = {
      timeZone = loc.timeZone or null;
      hardwareClockInLocalTime = isIn "dualboot-windows" (host.functionalities or []);
    };

    location = {
      latitude = loc.latitude or null;
      longitude = loc.longitude or null;
      provider = loc.locator or "geoclue2";
    };

    i18n = {
      defaultLocale = loc.defaultLocale or null;
    };
  };

  mkFonts = {
    pkgs,
    packages ? (with pkgs; [
      #~@ Monospace
      maple-mono.NF
      monaspace
      victor-mono

      #~@ System
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ]),
    emoji ? ["Noto Color Emoji"],
    monospace ? ["Maple Mono NF" "Monaspace Radon"],
    serif ? ["Noto Serif"],
    sansSerif ? ["Noto Sans"],
    ...
  }: {
    inherit packages;
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      hinting = {
        enable = true; # TODO: This should depend on the host specs
        style = "slight";
      };
      antialias = true;
      subpixel.rgba = "rgb";
      defaultFonts = {inherit emoji monospace serif sansSerif;};
    };
  };
  exports = {inherit mkNix mkLocale;};
in
  exports // {_rootAliases = exports;}
