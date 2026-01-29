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
    flake,
    lix,
    schema,
    paths,
    ...
  }:
    mapAttrs (
      _name: host: let
        modules = let
          all = {
            inherit
              ((getInputs {inherit host flake;}).modules)
              modulesPath
              baseModules
              coreModules
              homeModules
              hostModules
              ;
            inherit lix lib;
          };
          eval = evalModules {
            specialArgs = all // {inherit host schema paths;};
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
