{_, ...}: let
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.paths) mkSessionPaths;
  inherit (_.modules.home.programs) mkApps;
  inherit (_.modules.home.style) mkStyle;
  inherit (_.schema._) mkUI mkLocale mkApplications;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.construction) optionals;
  inherit (_.lists.transformation) flatten;

  __exports = {
    internal = {inherit mkUsers;};
    external = {
      mkHomeUsers = mkUsers;
    };
  };

  /**
  Build the attrset passed directly to `home-manager.users`.

  Each key is a username; each value is the per-user home-manager module
  function. Static store paths come in via `paths` (from `mkPaths`);
  runtime filesystem paths are derived per-user via `mkSessionPaths`.

  # Type
  ```
  mkUsers :: { host :: AttrSet, paths :: AttrSet } -> AttrSet
  ```
  */
  mkUsers = {
    host,
    inputs,
    modules,
    tree,
  }:
    mapAttrs (
      name: cfg: {
        nixosConfig,
        config,
        pkgs,
        ...
      }: let
        user = cfg // {inherit name;};
        enrichedInterface = mkUI {inherit host user;};
        inputsForHome = mkApps {inherit user inputs modules;};
        derivedPaths = mkSessionPaths {inherit config host user pkgs tree;};
        hmi = inputsForHome;
      in {
        # disabledModules = optionals (enrichedInterface.windowManager != "niri") [
        #   ../../../../Modules/nix/home/interface/manager/niri
        # ];

        _module.args = {
          style = mkStyle {inherit host user;};
          user = user // {interface = enrichedInterface;};
          apps = mkApplications {inherit host user;};
          keyboard = mkKeyboard {inherit host user;};
          locale = mkLocale {inherit host user;};
          paths = derivedPaths;
          inherit inputsForHome;
        };

        home = {inherit (nixosConfig.system) stateVersion;};

        imports =
          []
          ++ optionals
          (hmi?caelestia.module)
          [hmi.caelestia.module]
          ++ optionals
          (hmi?catppuccin.module)
          [hmi.catppuccin.module]
          ++ optionals
          (hmi?dank-material-shell.module)
          [hmi.dank-material-shell.module]
          ++ optionals
          (hmi?dms-plugin-registry.module)
          [hmi.dms-plugin-registry.module]
          ++ optionals
          (hmi?noctalia-shell.module)
          [hmi.noctalia-shell.module]
          ++ optionals
          (hmi?nvf.module)
          [hmi.nvf.module]
          ++ optionals
          (hmi?plasma.module)
          [hmi.plasma.module]
          ++ optionals
          (hmi?zen-browser.module)
          [hmi.zen-browser.module]
          ++ [tree.store.mod.home]
          ++ (user.imports or []);
      }
    ) (homeUsers host);
in
  __exports.internal // {__rootAliases = __exports.external;}
