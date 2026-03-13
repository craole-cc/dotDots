{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.filesystem.tree) mkTree;
  inherit (_.inputs.source) tryFlake;
  inherit (_.modules) core home;
  inherit (_.schema._) mkSchema;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;
  inherit (lib.modules) mkMerge;

  exports = {
    internal = {inherit mkSystems mkCore mkHome;};
    external = {inherit mkSystems;};
  };

  mkSystems = {
    self ? {},
    path ? src,
    args ? {},
    ...
  }: let
    tree = mkTree {inherit self;};
    schema = mkSchema {inherit tree;};
  in
    mapAttrs (
      _name: host: let
        class = host.class or "nixos";

        flake = let
          inherit (_.inputs.modules) mkModules;
          inherit (_.inputs.packages) mkPackages;
          inherit (_.inputs.source) mkInputs;
          source = tryFlake {inherit self path;};
          # inherit (source) nixpkgs;
          inputs = (mkInputs {self = source;}).resolved;
          packages = mkPackages {inherit inputs host;};
          modules = mkModules {inherit class inputs;};
        in {inherit inputs packages modules;};

        specialArgs =
          {
            inherit host schema class tree;
            lix = _;
            lib = lib.extend (self: super: {
              hm = flake.inputs.home-manager.lib.hm or {};
            });
          }
          // args;

        modules = let
          fromInputs = flake.modules;

          fromHost = mkCore {
            inherit host specialArgs;
            inherit (flake) modules inputs;
            inherit (flake.packages) nixpkgs;
          };

          fromEval = evalModules {
            specialArgs =
              specialArgs
              // {
                inherit (fromInputs.all) modulesPath baseModules;
                modules = fromInputs // {host = fromHost;};
              };

            modules =
              []
              ++ fromInputs.base
              ++ fromInputs.core
              ++ fromHost
              ++ [{config._module.args = specialArgs;}];
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
    modules,
    specialArgs,
  }:
    [
      {inherit nixpkgs;}
      (
        {
          config,
          tree,
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
            (mkHome {
              inherit host specialArgs inputs tree;
              modules = modules.home;
            })
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
    inputs,
    modules,
    tree,
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
      users = home.users.mkUsers {inherit inputs modules host tree;};
    };
  };
in
  exports.internal // {_rootAliases = exports.external;}
