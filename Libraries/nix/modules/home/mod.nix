{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) getDefaults;
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.environment) mkLocale;
  inherit (_.modules.home.programs) mkPrograms;
  inherit (_.modules.home.style) mkStyle;
  inherit (lib.attrsets) mapAttrs;

  modules = {inputs}: {
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

  mkModule = {
    name,
    variant ? "default",
  }:
    modules.${name}.${variant} or {};

  /**
  Produces the entire home-manager NixOS option block for all eligible users.
  Type: { host, specialArgs, paths } -> AttrSet
  */
  mkConfig = {
    host,
    specialArgs,
    mkHomeApps,
    paths,
  }: {
    home-manager = {
      backupFileExtension = "BaC";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs =
        (removeAttrs specialArgs ["paths"])
        // {
          lix = _;
          inherit host;
        };

      users =
        mapAttrs (
          name: user: {
            nixosConfig,
            config,
            pkgs,
            ...
          }: let
            inputsForHome = mkHomeApps {inherit user;};
            derivedPaths = getDefaults {inherit config host user pkgs paths;};
          in {
            _module.args = {
              style = mkStyle {inherit host user;};
              user = user // {inherit name;};
              apps = mkPrograms {inherit host user;};
              keyboard = mkKeyboard {inherit host user;};
              locale = mkLocale {inherit host;};
              paths = derivedPaths;
              inherit inputsForHome;
            };

            home = {inherit (nixosConfig.system) stateVersion;};

            imports =
              []
              ++ [paths.store.pkgs.home]
              ++ (user.imports or [])
              ++ (with inputsForHome; [
                caelestia.module
                catppuccin.module
                dank-material-shell.module
                noctalia-shell.module
                nvf.module
                plasma.module
                zen-browser.module
              ]);
          }
        )
        (homeUsers host);
    };
  };

  exports = {
    inherit
      mkConfig
      modules
      # homeMods
      # mkHomeModule
      # mkHomeApps
      # mkHome
      ;
  };
in
  exports
  // {
    _rootAliases = {
      mkHome = mkConfig;
      mkHomeModule = mkModule;
      homeModules = modules;
    };
  }
