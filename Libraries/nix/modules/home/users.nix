{
  _,
  lib,
  ...
}: let
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.paths) mkSessionPaths;
  inherit (_.modules.home.programs) mkApps;
  inherit (_.modules.home.style) mkStyle;
  inherit (_.schema._) mkUI mkLocale mkApplications;
  inherit (lib.attrsets) mapAttrs;

  __exports = {
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
        system = pkgs.stdenv.hostPlatform.system;
        enrichedUser = user // {inherit name;};
        enrichedInterface = mkUI {
          inherit host;
          user = enrichedUser;
        };
        inputsForHome = mkApps {inherit user inputs modules;};
        derivedPaths = mkSessionPaths {inherit config host user pkgs tree;};
      in {
        _module.args = {
          style = mkStyle {inherit host user;};
          user = enrichedUser // {interface = enrichedInterface;};
          apps = mkApplications {
            inherit host;
            user = enrichedUser;
          };
          keyboard = mkKeyboard {
            inherit host;
            user = enrichedUser;
          };
          locale = mkLocale {
            inherit host;
            user = enrichedUser;
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
  __exports.internal // {_rootAliases = __exports.external;}
