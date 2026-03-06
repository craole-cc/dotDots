{
  _,
  src,
  lib,
  ...
}:
let
  inherit (_.lists.predicates) mostFrequent;
  inherit (_.modules.inputs.packages) mkPackages mkOverlays;
  inherit (builtins) getFlake;
  inherit (lib.attrsets)
    attrValues
    genAttrs
    attrNames
    mapAttrs
    mapAttrsToList
    optionalAttrs
    ;
  inherit (lib.debug) traceIf;
  inherit (lib.lists)
    findFirst
    unique
    last
    flatten
    ;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) pathExists;
  flakeInputs = _.modules.inputs.resolution;

  mkModule =
    {
      name,
      modules,
      variant ? "default",
    }:
    modules.${name}.${variant} or { };

  mkModules =
    {
      inputs,
      host,
      packages,
      specialArgs,
      config,
      overlays,
    }:
    let
      class = host.class or "nixos";
      modulesPath = "${inputs.nixpkgs}/nixos/modules";
      baseModules = import "${modulesPath}/module-list.nix";
      nixpkgs = getNixPkgs {
        inherit
          host
          config
          inputs
          overlays
          ;
      };
      coreModules = getCoreModules { inherit class inputs; };
      homeModules = getHomeModules { inherit inputs; };
      hostModules = mkCoreConf {
        inherit nixpkgs config specialArgs;
        inputs = packages;
      };
    in
    {
      inherit
        modulesPath
        baseModules
        coreModules
        homeModules
        hostModules
        nixpkgs
        ;
    };

  mkConfig =
    {
      flake ? { },
      host ? { },
      specialArgs ? { },
      self ? { },
      path ? { },
      ...
    }:
    let
      flake' = if flake != { } then flake else flakeAttrs { inherit self path; };

      host' =
        if host != { } then
          host
        else
          hostAttrs {
            nixosConfigurations = flake.nixosConfigurations or { };
            system = host.system or (getSystems { }).system;
          };

      inputs = flakeInputs.all { flake = flake'; };

      config = {
        allowUnfree = host.packages.allowUnfree or false;
        allowBroken = host.packages.allowBroken or false;
      };

      packages = mkPackages { inherit inputs; };

      overlays = mkOverlays {
        inherit inputs packages config;
      };

      modules = getModules {
        inherit
          inputs
          packages
          config
          overlays
          specialArgs
          ;
        host = host';
        # paths =
      };
    in
    {
      inherit
        inputs
        modules
        overlays
        packages
        ;
    };
  # =============================================================
  __doc = ''
    Modules
  '';
  exports = { inherit mkModule mkModules mkConfig; };
in
exports
// {
  inherit __doc;
  _rootAliases = {
    inherit (exports) mkModule mkModules;
    mkSystem = mkConfig;
  };
}
