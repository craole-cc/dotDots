{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;
  inherit (_.modules.resolution) getInputs;

  mkSystem = {
    hosts,
    args,
    ...
  }:
    mapAttrs (
      _name: host: let
        specialArgs = args // {inherit host;};
        inherit (specialArgs) flake;
        inputs = getInputs {inherit host flake specialArgs;};

        modules = let
          all = {
            inherit
              (inputs.modules)
              modulesPath
              baseModules
              coreModules
              homeModules
              hostModules
              ;
          };
          eval = evalModules {
            specialArgs = specialArgs // all;
            modules =
              []
              ++ all.baseModules
              ++ all.coreModules
              ++ all.hostModules
              ++ [{config._module.args = all;}];
          };
        in {inherit all eval;};
      in
        if (host.class or "nixos") == "darwin"
        then
          (
            modules.eval
            // {system = modules.eval.config.system.build.toplevel;}
          )
        else modules.eval
    )
    hosts;
  exports = {inherit mkSystem;};
in
  exports // {_rootAliases = exports;}
