{
  _,
  lib,
  ...
}: let
  inherit (_.configuration.inputs.modules) mkCore mkHome;
  inherit (lib.attrsets) mapAttrs;
  inherit (lib.modules) evalModules;

  mkModule = {
    name,
    modules,
    variant ? "default",
  }:
    modules.${name}.${variant} or {};

  mkModules = {
    inputs,
    host,
    packages,
    specialArgs,
    config,
    overlays,
  }: let
    class = host.class or "nixos";
    outPath = inputs.nixpkgs;
    modulesPath = "${inputs.nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    nixpkgs =
      {
        hostPlatform = host.system;
        inherit config overlays;
      }
      // (
        if (host.class or "nixos") == "darwin"
        then {source = outPath;}
        else {flake.source = outPath;}
      );
    coreModules = mkCore {inherit class inputs;};
    homeModules = mkHome {inherit inputs;};
    # hostModules = mkCoreConf {
    #   inherit nixpkgs config specialArgs;
    #   inputs = packages;
    # };
  in {
    inherit
      modulesPath
      baseModules
      coreModules
      homeModules
      hostModules
      nixpkgs
      ;
  };

  mkConfig = {
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
          };

          specialArgs = {
            inherit lix lib host schema;
            inherit (all) modulesPath;
            paths = paths // {local = paths.mkLocal host.paths.dots;};
            modules = all;
          };

          eval = evalModules {
            inherit specialArgs;
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

  exports = {
    inherit mkConfig;
    mkSystem = mkConfig;
  };
in
  exports // {_rootAliases = {inherit (exports) getSystem;};}
