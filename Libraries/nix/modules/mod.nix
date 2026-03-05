{_, ...}: let
  inherit (_.modules.core.mod) mkCore mkNixPkgs mkCoreMods;

  mkModules = {
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
    nixpkgs = mkNixPkgs {inherit host config inputs overlays;};
    coreModules = mkCoreMods {inherit class inputs;};
    hostModules = mkCore {
      inherit nixpkgs config specialArgs;
      inputs = packages;
    };
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

  exports = {inherit mkModules;};
in
  exports // {_rootAliases = exports;}
