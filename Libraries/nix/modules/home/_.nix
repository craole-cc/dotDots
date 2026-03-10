{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) getDefaults;
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.environment) mkLocale;
  inherit (_.modules.home.programs) mkPrograms mkHomeApps;
  inherit (_.modules.home.style) mkStyle;
  inherit (lib.attrsets) mapAttrs;

  exports = {
    inherit mkHome;
    inherit
      homeUsers
      mkKeyboard
      mkLocale
      mkPrograms
      mkHomeApps
      mkStyle
      ;
  };

  /**
  Produces the entire home-manager NixOS option block for all eligible users.
  Type: { host, specialArgs, paths } -> AttrSet
  */
  mkHome = {
    host,
    specialArgs,
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
in
  exports
  // {
    _rootAliases = {
      # inherit (exports) mkHome;
    };
  }
