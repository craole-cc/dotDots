{_, ...}: let
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.construction) optionals;
  inherit (_.modules.core.users) homeUsers;
  inherit (_.modules.home.control) mkKeyboard;
  inherit (_.modules.home.paths) mkSessionPaths;
  inherit (_.modules.home.programs) mkApps;
  inherit (_.modules.home.style) mkStyle;
  inherit (_.schema.construction) mkUI mkLocale mkApplications;

  __exports = {
    internal = {inherit mkUsers;};
    external = {
      mkHomeUsers = mkUsers;
    };
  };

  /**
  Build the attrset passed directly to `home-manager.users` (NixOS-embedded
  mode), or, when `standalone = true`, the per-user module list handed
  straight to `home-manager.lib.homeManagerConfiguration` (see `mkHomes` in
  `Libraries/nix/modules/construction.nix`).

  Every concern here - style, keyboard, locale, session paths, and the
  `imports` list of home-manager modules pulled in from flake inputs - is
  identical between the two modes and is not branched on `standalone`.
  Only two facts genuinely differ between a NixOS-embedded user and a
  standalone one, and those are the only places `standalone` is consulted:

  1. `home.stateVersion` - inside a NixOS eval this is borrowed from the
      parent system's `nixosConfig.system.stateVersion` (the special-arg
      `home-manager.nixosModules.home-manager` injects into each user
      submodule). Standalone home-manager has no parent NixOS config to
      borrow from, so it falls back to `host.stateVersion`.

  2. `home.username` / `home.homeDirectory` - inside a NixOS eval these are
      inferred from the matching `users.users.<name>` entry created by
      `Libraries/nix/modules/core/users.nix`'s `mkUsers` (unrelated function,
      same name, different module - core-level system users vs. this
      home-level per-user module builder). Standalone home-manager has no
      such entry to infer from, so both must be set explicitly.

  # Type
  ```
  mkUsers :: {
    host :: AttrSet,
    inputs :: AttrSet,
    modules :: AttrSet,
    tree :: AttrSet,
    standalone :: bool ? false,
  } -> AttrSet
  ```
  */
  mkUsers = {
    host,
    inputs,
    modules,
    paths ? host.paths or {},
    standalone ? false,
  }:
    mapAttrs (
      name: spec: {
        config,
        pkgs,
        ...
      } @ args: let
        nixosConfig = args.nixosConfig or null;
        user = spec // {inherit name;};

        inputs' = mkApps {inherit user inputs modules;};
        mkInput = name:
          optionalAttrs
          (inputs' ? ${name}.module)
          inputs'.${name};
        mkInputModules = names:
          concatMap (name: let
            input = mkInput name;
          in
            optionals
            (input != {})
            [inputs'.${name}.module])
          names;

        enrichedInterface = mkUI {inherit host user;};
      in {
        _module.args = {
          style = mkStyle {inherit host user;};
          user = user // {interface = enrichedInterface;};
          apps = mkApplications {inherit host user;};
          keyboard = mkKeyboard {inherit host user;};
          locale = mkLocale {inherit host user;};
          paths = mkSessionPaths {inherit config host user pkgs paths;};
          inputs = inputs';
          inherit mkInput mkInputModules;
          # inherit inputs inputs';
          inputsForHome = inputs'; #TODO: Direct callers to use inputs or mkInput instead
        };

        home =
          {
            stateVersion =
              if standalone
              then (host.stateVersion or "26.05")
              else nixosConfig.system.stateVersion;
          }
          // optionalAttrs standalone {
            username = name;
            homeDirectory = "/home/${name}";
          };

        imports =
          mkInputModules [
            "caelestia"
            "catppuccin"
            "dms-shell"
            "dms-plugin-registry"
            "noctalia-shell"
            "nvf"
            "plasma"
            "zen-browser"
          ]
          ++ [paths.store.mod.home]
          ++ (user.imports or []);
      }
    ) (homeUsers host);
in
  __exports.internal // {__rootAliases = __exports.external;}
