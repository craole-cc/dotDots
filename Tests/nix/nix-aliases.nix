{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  moduleLix =
    lix
    // {
      toolkit.commandsFor = _packages: {
        binaries = {};
        aliases = {
          lsdLong = "lsd --long --git --almost-all";
          lsdTree = "lsd --tree";
          lsdRecursive = "lsd --long --git --recursive";
        };
      };
      toolkit.binaries = {
        nhs = "nh os switch";
        nhr = "nh os repl";
        nhc = "nh clean all";
      };
      modules =
        lix.modules
        // {
          construction =
            lix.modules.construction
            // {
              mkContext = _arguments: {
                cfg.repo = {
                  name = "dots";
                  home = "/checkout";
                };
              };
              mkConfig = specification: specification.outputs;
            };
          core =
            lix.modules.core
            // {
              software = {
                mkNix = _arguments: {};
                mkMaintenance = _arguments: {};
              };
            };
        };
    };
  module = import ../../Modules/nix/core/system/nix.nix {
    lix = moduleLix;
    config = {};
    host.class = "nixos";
    inputs = {};
    names = {};
    paths = {};
    pkgs = {};
    top = "_";
  };
  evaluated = lib.evalModules {
    modules = [
      {
        options.environment.shellAliases = lib.mkOption {type = lib.types.attrsOf lib.types.str;};
        options.nixpkgs.config = lib.mkOption {type = lib.types.attrs;};
      }
      {config = module;}
    ];
  };
  aliases = evaluated.config.environment.shellAliases;
  generic = import ../../Modules/nix/core/environment/aliases.nix {
    config = {};
    lix =
      moduleLix
      // {
        modules =
          moduleLix.modules
          // {
            construction =
              moduleLix.modules.construction
              // {
                mkConfig = specification: specification.options.default.default;
              };
          };
      };
  };
in {
  checkoutStatusOwnedByNix = lib.hasInfix "/checkout" aliases.dotsStatus;
  checkoutShortcutPreserved = aliases.edit-dots == "$EDITOR /checkout";
  replShortcutPreserved = aliases.repl-home == "nix repl --show-trace /checkout#nixosConfigurations.$(hostname).config.home-manager.users.$USER";
  nixHelperPreserved = aliases.nhs == "nh os switch";
  generalDefaultsHaveNoCheckoutAliases = !(generic ? dotsStatus || generic ? edit-dots || generic ? nxs || generic ? repl-home);
  generalDefaultsPreserved = generic.ll == "lsd --long --git --almost-all";
}
