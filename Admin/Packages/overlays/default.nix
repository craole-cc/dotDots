{
  inputs ? {},
  lib ? {},
  host ? {},
}: let
  inherit (lib.attrsets) mapAttrs;
  allowUnfree = host.packages.allowUnfree or false;

  # Safe fallback functions
  safeImport = path: attrs:
    builtins.tryEval (import path attrs).value or {};
in [
  # 1. Flake inputs → pkgs.inputs.${name}
  (final: _: {
    inputs = mapAttrs (_: flake: let
      system = final.system;
      legacyPackages = (flake.legacyPackages or {}).${system} or {};
      packages = (flake.packages or {}).${system} or {};
    in
      if legacyPackages != {}
      then legacyPackages
      else packages)
    inputs;
  })

  # 2. Stable channel
  (final: _: {
    stable = import inputs.nixPackagesStable {
      system = final.system;
      config.allowUnfree = allowUnfree;
    };
  })

  # 3. Unstable channel
  (final: _: {
    unstable = import inputs.nixPackagesUnstable {
      system = final.system;
      config.allowUnfree = allowUnfree;
    };
  })

  # 4. Modifications
  (final: prev: {
    brave = prev.brave.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    };
  })

  # 5. Custom packages/plugins - FIXED syntax
  (
    final: prev:
      (safeImport ../custom {
        pkgs = final;
        inherit lib;
      })
      // {
        vimPlugins =
          (prev.vimPlugins or {})
          // (safeImport ../plugins/vim {
            pkgs = final;
            inherit lib;
          });
      }
  )
]
