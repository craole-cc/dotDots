{
  _,
  lib,
  ...
}: let
  inherit (_.inputs.resolution) inputs;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.lists) optionals;

  exports = {
    inherit inputs coreModules homeModules mkModule mkModules;
    getCoreInputModules = coreModules;
    getHomeInputModules = homeModules;
    mkInputModules = mkModules;
    mkInputModule = mkModule;
  };

  /**
  Look up a module by name and variant from a modules attrset.

  # Type
  ```nix
  mkModule :: { name :: string, modules :: AttrSet?, variant :: string? } -> module
  ```
  */
  mkModule = {
    name,
    modules ? homeModules,
    variant ? "default",
  }:
    modules.${name}.${variant} or {};

  /**
  Return the list of core NixOS/Darwin modules for a host class.

  # Type
  ```nix
  coreModules :: { class :: "nixos" | "darwin" } -> [module]
  ```
  */
  coreModules = {class ? "nixos", ...}:
    (
      if class == "darwin"
      then [
        (inputs.home-manager.darwinModules.home-manager or {})
        (inputs.stylix.darwinModules.stylix or {})
      ]
      else [
        (inputs.home-manager.nixosModules.home-manager or {})
        (inputs.stylix.nixosModules.stylix or {})
        (inputs.catppuccin.nixosModules.default or {})
        (inputs.chaotic.nixosModules.default or {})
      ]
    )
    ++ optionals (class == "darwin") [
      {
        system = {
          checks.verifyNixPath = false;
          darwinVersionSuffix = ".${
            inputs.nix-darwin.shortRev
            or inputs.nix-darwin.dirtyShortRev
            or "dirty"
          }";
          darwinRevision =
            inputs.nix-darwin.rev or inputs.nix-darwin.dirtyRev or "dirty";
        };
      }
    ];

  /**
  Attrset of all home-manager modules provided by flake inputs.
  */
  homeModules = {
    dank-material-shell = {
      default = inputs.dank-material-shell.homeModules.default or {};
      niri = inputs.dank-material-shell.homeModules.niri or {};
    };
    noctalia-shell = inputs.noctalia-shell.homeModules or {};
    caelestia = inputs.caelestia.homeManagerModules or {};
    catppuccin = inputs.catppuccin.homeModules or {};
    nvf = {default = inputs.nvf.homeManagerModules.default or {};};
    plasma = {default = inputs.plasma.homeModules.plasma-manager or {};};
    zen-browser = {
      twilight = inputs.zen-browser.homeModules.twilight or {};
      default = inputs.zen-browser.homeModules.default or {};
      beta = inputs.zen-browser.homeModules.beta or {};
    };
  };

  /**
  Build the full module attrset for a host.

  # Type
  ```nix
  mkModules :: { class :: "nixos" | "darwin" } -> { all, base, core, home, path, ... }
  ```
  */
  mkModules = {class ? "nixos", ...}: let
    path = "${inputs.nixpkgs}/nixos/modules";
    base = import "${path}/module-list.nix";
    core = coreModules {inherit class;};
    home = homeModules;
    all = {
      baseModules = base;
      coreModules = core;
      homeModules = home;
      modulesPath = path;
    };
  in
    {inherit all base core home path;} // all;
in
  exports
  // {
    _rootAliases = {
      inherit
        (exports)
        getCoreInputModules
        getHomeInputModules
        mkInputModules
        mkInputModule
        ;
    };

    _tests = runTests {
      mkModule = {
        returnsEmptyWhenVariantMissing = mkTest {
          desired = {};
          outcome = mkModule {
            name = "nonexistent";
            modules = {};
          };
          command = ''mkModule { name = "nonexistent"; modules = {}; }'';
        };
        fallsBackToEmptyOnMissingVariant = mkTest {
          desired = {};
          outcome = mkModule {
            name = "nvf";
            modules = {nvf = {};};
            variant = "missing";
          };
          command = ''mkModule { name = "nvf"; modules = { nvf = {}; }; variant = "missing"; }'';
        };
        resolvesExistingVariant = mkTest {
          desired = "ok";
          outcome = mkModule {
            name = "myMod";
            modules = {myMod.default = "ok";};
          };
          command = ''mkModule { name = "myMod"; modules = { myMod.default = "ok"; }; }'';
        };
      };

      homeModules = {
        hasNvf = mkTest' true (homeModules ? nvf);
        hasZenBrowser = mkTest' true (homeModules ? zen-browser);
        hasCatppuccin = mkTest' true (homeModules ? catppuccin);
        zenHasTwilight = mkTest' true (homeModules.zen-browser ? twilight);
        zenHasBeta = mkTest' true (homeModules.zen-browser ? beta);
      };

      coreModules = {
        nixosReturnsList = mkTest' true (builtins.isList (coreModules {class = "nixos";}));
        darwinReturnsList = mkTest' true (builtins.isList (coreModules {class = "darwin";}));
        defaultsToNixos = mkTest' true (builtins.isList (coreModules {}));
      };
    };
  }
