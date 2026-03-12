{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.filesystem.tree) mkTree;
  inherit (_.modules) core home;
  inherit (_.modules.inputs.source) tryFlake;
  inherit (_.schema._) mkSchema;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;
  inherit (lib.modules) mkMerge;

  paths = mkTree {};
  schema = mkSchema {};
  lix = _;

  exports = {inherit mkSystem mkCore mkHome;};

  mkSystem = {
    self ? {},
    path ? src,
    args ? {},
    ...
  }:
    mapAttrs (
      _name: host: let
        class = host.class or "nixos";

        flake = let
          inherit (_.modules.inputs.modules) mkModules;
          inherit (_.modules.inputs.packages) mkPackages;
          inherit (_.modules.inputs.source) mkInputs;
          source = tryFlake {inherit self path;};
          inputs = mkInputs {self = source;};
          packages = mkPackages {inherit inputs host;};
          modules = mkModules {
            inherit class;
            inputs = inputs.resolved;
          };
        in {inherit inputs packages modules;};

        specialArgs = {inherit lix lib host schema class paths;} // args;

        modules = let
          fromInputs = flake.modules;
          fromHost = mkCore {
            inherit host specialArgs;
            inherit (flake.packages) nixpkgs inputs;
          };

          fromEval = evalModules {
            modules =
              {}
              ++ fromInputs.base
              ++ fromInputs.core
              ++ fromHost
              ++ [
                {
                  config._module.args =
                    specialArgs
                    // {
                      inherit (fromInputs.all) modulesPath;
                      modules = fromInputs // {host = fromHost;};
                    };
                }
              ];
          };
        in {inherit fromInputs fromHost fromEval;};
      in
        if class == "darwin"
        then
          (
            modules.fromEval
            // {system = modules.fromEval.config.system.build.toplevel;}
          )
        else modules.fromEval
    )
    schema.hosts;

  mkCore = {
    host,
    nixpkgs,
    inputs,
    specialArgs,
  }:
    [
      {inherit nixpkgs;}
      (
        {
          config,
          paths,
          pkgs,
          ...
        }: let
          inherit (core.hardware) mkBoot mkAudio mkFileSystems mkNetwork;
          inherit (core.software) mkClean mkNix;
          inherit (core.environment) mkEnvironment mkLocale;
          inherit (core.programs) mkPrograms;
          inherit (core.services) mkServices;
          inherit (core.style) mkFonts;
          # inherit (core.style) mkFonts mkStyle;
          inherit (core.users) mkUsers;
        in
          mkMerge [
            (mkNix {inherit host pkgs;})
            (mkNetwork {inherit host pkgs;})
            (mkBoot {inherit host pkgs;})
            (mkFileSystems {inherit host;})
            (mkLocale {inherit host;})
            (mkAudio {inherit host;})
            (mkFonts {inherit host pkgs;})
            # (mkStyle {inherit host pkgs;}) # TODO: Not ready, build errors
            (mkClean {inherit host;})
            (mkEnvironment {inherit config host pkgs inputs;})
            (mkServices {inherit config host;})
            (mkPrograms {inherit host;})
            (mkUsers {inherit host pkgs;})
            (mkHome {inherit host specialArgs paths;})
          ]
      )
    ]
    ++ (host.imports or []);

  /**
  Produce the entire home-manager NixOS option block for all eligible users.

  `paths` is the static store/local path tree from `mkPaths` — passed
  explicitly so it is never buried in `specialArgs`. Runtime per-user paths
  are derived inside `mkUsers` via `mkSessionPaths`.

  # Type
  ```
  mkHome :: { host        :: AttrSet
            , specialArgs :: AttrSet
            , paths       :: AttrSet
            } -> AttrSet
  ```
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
        specialArgs
        // {
          lix = _;
          inherit host;
        };
      users = home.mkUsers {inherit host paths;};
    };
  };
in
  exports // {_rootAliases = {inherit (exports) mkSystem;};}
