{_, ...}: let
  inherit (_.modules.core.mod) mkNixpkgs;
  mkCoreConf = _.modules.core.mod.mkConfig;
  mkCoreConf = _.modules.core.mod.mkConfig;
  mkCoreMods = _.modules.core.mod.mkModules;

  modules = {
    inputs,
    host,
    packages,
    specialArgs,
    config,
    overlays,
  }: let
    class = host.class or "nixos";
    modulesPath = "${inputs.nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    nixpkgs = mkNixpkgs {inherit host config inputs overlays;};
    coreModules = mkCoreMods {inherit class inputs;};
    hostModules = mkCoreConf {
      inherit nixpkgs config specialArgs;
      inputs = packages;
    };
    # homeModules = mkHome {};
  in {
    inherit
      modulesPath
      baseModules
      coreModules
      hostModules
      # homeModules
      nixpkgs
      ;
  };

  exports = {inherit modules;};
in
  exports // {_rootAliases = exports;}
