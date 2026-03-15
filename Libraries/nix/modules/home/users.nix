{
  _,
  lib,
  ...
}: let
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.environment) mkLocale;
  inherit (_.modules.home.paths) mkSessionPaths;
  inherit (_.modules.home.programs) mkPrograms mkApps;
  inherit (_.modules.home.style) mkStyle;
  inherit (_.schema._) mkUI;
  inherit (lib.attrsets) mapAttrs;

  exports = {
    internal = {inherit mkUsers;};
    external = {mkHomeUsers = mkUsers;};
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
      name: user: {
        nixosConfig,
        config,
        pkgs,
        ...
      }: let
        enrichedInterface = mkUI {
          inherit host;
          user = user // {inherit name;};
        };
        inputsForHome = mkApps {inherit user inputs modules;};
        derivedPaths = mkSessionPaths {inherit config host user pkgs tree;};
      in {
        _module.args = {
          style = mkStyle {inherit host user;};
          user =
            user
            // {
              inherit name;
              interface = enrichedInterface; # ← per-user normalized interface
            };
          apps = mkPrograms {inherit host user;};
          keyboard = mkKeyboard {inherit host user;};
          locale = mkLocale {
            inherit host;
            inherit user;
          };
          paths = derivedPaths;
          inherit inputsForHome;
        };

        home = {inherit (nixosConfig.system) stateVersion;};

        imports =
          (with inputsForHome; [
            caelestia.module
            catppuccin.module
            dank-material-shell.module
            noctalia-shell.module
            nvf.module
            plasma.module
            zen-browser.module
          ])
          ++ [tree.store.mod.home]
          ++ (user.imports or []);
      }
    ) (homeUsers host);
in
  exports.internal // {_rootAliases = exports.external;}
