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

        #~@ Modules
        inherit (inputs.modules) modulesPath baseModules coreModules homeModules hostModules;

        allMods = {
          inherit
            modulesPath
            baseModules
            homeModules
            coreModules
            hostModules
            moduleArgs
            ;
        };
        moduleArgs = [
          {
            config = {
              _module.args = allMods;
              # nixpkgs.flake.source = flake.outPath;
            };
          }
        ];

        moduleEval = evalModules {
          specialArgs = specialArgs // allMods;
          modules =
            baseModules
            ++ homeModules
            ++ coreModules
            ++ hostModules
            ++ moduleArgs;
        };
      in
        if (host.class or "nixos") == "darwin"
        then (moduleEval // {system = moduleEval.config.system.build.toplevel;})
        else moduleEval
    )
    hosts;

  exports = {inherit mkSystem;};
in
  exports // {_rootAliases = exports;}
