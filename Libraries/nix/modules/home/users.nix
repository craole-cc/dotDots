{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) getDefaults;
  inherit (_.modules.core.users) hostUsers;
  inherit (_.modules.home.environment) mkLocale;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.style) mkStyle;
  inherit (_.modules.home.programs) mkApps;
  inherit (lib.attrsets) filterAttrs mapAttrs removeAttrs;

  /**
  Filter users eligible for home-manager configuration.
  Excludes: service users, guest users, and empty/undefined users.

  Type: AttrSet -> AttrSet

  Example:
    homeManagerUsers { users.data.enabled = {
      alice = { role = "admin"; };
      cc = { role = "service"; };
    }; }
    => { alice = { role = "admin"; }; }
  */
  homeUsers = host:
    filterAttrs
    (_: user:
      user
      != {} #? User must exist
      && (user.role or null) != "service" # Not a system service
      && (user.role or null) != "guest") # Not a guest account
    
    (hostUsers host);

  /**
  Produces the entire home-manager NixOS option block for all eligible users.
  Type: { host, specialArgs, paths } -> AttrSet
  */
  mkUsers = {
    host,
    specialArgs,
    mkHomeModuleApps,
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
            inputsForHome = mkHomeModuleApps {inherit user;};
            derivedPaths = getDefaults {inherit config host user pkgs paths;};
          in {
            _module.args = {
              style = mkStyle {inherit host user;};
              user = user // {inherit name;};
              apps = mkApps {inherit host user;};
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

  exports = {inherit mkUsers homeUsers;};
in
  exports
  // {
    _rootAliases = {
      inherit homeUsers;
      mkHomeUsers = mkUsers;
    };
  }
