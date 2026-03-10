{
  _,
  lib,
  ...
}: let
  inherit (_.configuration.inputs.generators) mkInputModules mkInputPackages;
  inherit (_.configuration.core.mod) mkCoreModules;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;
  inherit (_.modules.core._) mkCore;
  inherit (_.modules.home._) mkHome;

  exports = {inherit mkSystem mkCore mkHome;};

  mkSystem = {
    hosts,
    lix,
    schema,
    paths,
    ...
  }:
    mapAttrs (
      _name: host: let
        class = host.class or "nixos";
        specialArgs = {
          inherit lix lib host schema class;
          paths = paths // {local = paths.mkLocal host.paths.dots;};
        };
        packages = mkInputPackages {inherit host;};
        modules = let
          fromInputs = mkInputModules {inherit class;};
          fromHost = mkCoreModules {
            inherit host specialArgs;
            inherit (packages) nixpkgs inputs;
          };
          fromEval = evalModules {
            specialArgs =
              specialArgs
              // {
                inherit (fromInputs.all) modulesPath;
                modules = fromInputs // {host = fromHost;};
              };
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
    hosts;
in
  exports // {_rootAliases = {inherit (exports) mkSystem;};}
