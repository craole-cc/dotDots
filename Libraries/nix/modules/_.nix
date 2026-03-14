{
  _,
  lib,
  ...
}: let
  __doc = ''
    Module Evaluation and System Generation

    Provides the orchestration layer for turning discovered hosts, resolved
    flake inputs, generated package sets, and assembled module lists into
    fully evaluated system configurations.

    This file is responsible for two major tasks:

    1. Evaluating host systems via `evalModules`.
    2. Generating per-system flake-style output matrices from a function.
  '';

  __exports = {
    internal = {inherit mkSystems mkCore mkHome mkFlakeOutputs mkTree;};
    external = {inherit mkSystems mkFlakeOutputs;};
  };

  inherit (_.filesystem.tree) mkTree;
  inherit (_.hardware.system) getSystems;
  inherit (_.inputs.modules) mkModules;
  inherit (_.inputs.packages) mkPackages;
  inherit (_.modules) core home;
  inherit (lib.attrsets) attrNames genAttrs mapAttrs;
  inherit (lib.modules) evalModules mkMerge;

  /**
  Evaluate all hosts from the discovered schema into concrete system outputs.

  Builds the repository tree, derives the host schema, resolves flake inputs,
  generates package and module sets for each host, and evaluates the final
  module graph through `lib.modules.evalModules`.

  For Darwin hosts, this also exposes the built system derivation under
  `system` for easier downstream consumption.

  # Args:
    self: Optional already-evaluated flake.
    path: Filesystem path to the source flake.
    args: Extra arguments merged into `specialArgs`.
    ...: Additional arguments reserved for future extension.

  # Returns:
    An attrset keyed by host name, where each value is the evaluated module
    result for that host.
  */
  mkSystems = {
    inputs,
    tree,
    schema,
    extraArgs ? {},
    ...
  }:
    mapAttrs (
      _: host: let
        class = host.class or "nixos";

        flakeArgs = let
          packages = mkPackages {inherit host inputs;};
          modules = mkModules {inherit class inputs;};
        in {inherit inputs packages modules;};

        specialArgs = {inherit host class;} // extraArgs;

        modules = let
          fromInputs = flakeArgs.modules;
          fromHost = mkCore {
            inherit host specialArgs tree;
            inherit (flakeArgs) modules inputs;
            inherit (flakeArgs.packages) nixpkgs;
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
              ++ (host.imports or [])
              ++ [tree.mod.core.store]
              ++ [{config._module.args = specialArgs;}];
          };
        in {inherit fromInputs fromHost fromEval;};
      in
        if class == "darwin"
        then
          modules.fromEval
          // {system = modules.fromEval.config.system.build.toplevel;}
        else modules.fromEval
    )
    schema.hosts;

  /**
  Build the host-specific core module list used during system evaluation.

  Produces the base module stack for a host by combining low-level hardware,
  networking, environment, services, programs, users, and home-manager glue.
  The result is returned as a module list suitable for `evalModules`.

  # Args:
    host: The enriched host definition.
    nixpkgs: The resolved nixpkgs source/configuration attrset.
    inputs: Canonically resolved flake inputs.
    modules: Resolved input-provided module sets.
    specialArgs: Extra arguments forwarded into module evaluation.

  # Returns:
    A list of modules for the target host, including any host-local imports.
  */
  mkCore = {
    host,
    nixpkgs,
    inputs,
    modules,
    specialArgs,
    tree,
  }: [
    {inherit nixpkgs;}
    (mkHome {
      inherit host specialArgs tree inputs;
      modules = modules.home;
    })
  ];
  # mkCore = {
  #   host,
  #   nixpkgs,
  #   inputs,
  #   modules,
  #   specialArgs,
  # }:
  #   [
  #     {inherit nixpkgs;}
  #     (
  #       {
  #         config,
  #         tree,
  #         pkgs,
  #         ...
  #       }: let
  #         inherit (core.hardware) mkBoot mkAudio mkFileSystems mkNetwork;
  #         inherit (core.software) mkClean mkNix;
  #         inherit (core.environment) mkEnvironment mkLocale;
  #         inherit (core.programs) mkPrograms;
  #         inherit (core.services) mkServices;
  #         inherit (core.style) mkFonts;
  #         inherit (core.users) mkUsers;
  #       in
  #         mkMerge [
  #           (mkNix {inherit host pkgs;})
  #           (mkNetwork {inherit host pkgs;})
  #           (mkBoot {inherit host pkgs;})
  #           (mkFileSystems {inherit host;})
  #           (mkLocale {inherit host;})
  #           (mkAudio {inherit host;})
  #           (mkFonts {inherit host pkgs;})
  #           (mkClean {inherit host;})
  #           (mkEnvironment {inherit config host pkgs inputs;})
  #           (mkServices {inherit config host;})
  #           (mkPrograms {inherit host;})
  #           (mkUsers {inherit host pkgs;})
  #           (mkHome {
  #             inherit host specialArgs tree;
  #             inputs = inputs.resolved;
  #             modules = modules.home;
  #           })
  #         ]
  #     )
  #   ]
  #   ++ host.imports or [];

  /**
  Produce the complete Home Manager option block for the current host.

  Configures Home Manager to reuse the system package set, forward shared
  special arguments, and generate per-user configurations through the
  home user builder.

  # Args:
    host: The current host definition.
    specialArgs: Arguments forwarded into Home Manager modules.
    inputs: Canonically resolved flake inputs.
    modules: Resolved Home Manager module set.
    tree: Repository tree metadata used by downstream user builders.

  # Returns:
    A module fragment defining the `home-manager` configuration block.
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
          lib = lib.extend (_self: _super: {
            hm = inputs.home-manager.lib.hm or {};
          });
        };
      users = home.users.mkUsers {inherit inputs modules host tree;};
    };
  };

  /**
  Generate system-indexed flake-style outputs from a function.

  Evaluates the provided function for every supported system, then inverts
  the result so top-level output names map to per-system values such as
  `packages.<system>.*`, `devShells.<system>.*`, or similar output groups.

  # Args:
    flake: Optional flake providing legacy package sets.
    nixpkgs: Optional nixpkgs input.
    legacyPackages: Optional pre-evaluated legacy package attrset.
    system: Preferred system to use for deriving output names.
    hosts: Optional host definitions used to derive supported systems.
    fn: Function receiving `{ system, pkgs }` and returning flake-style outputs.

  # Returns:
    An attrset whose top-level keys are output groups and whose values are
    attrsets keyed by system.
  */
  mkFlakeOutputs = {
    flake ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? builtins.currentSystem or null,
    hosts ? {},
    fn,
  }: let
    inherit
      (getSystems {
        inherit
          flake
          nixpkgs
          legacyPackages
          system
          hosts
          ;
      })
      pkgsFor
      derived
      all
      ;

    perSystem = (genAttrs all) (sys:
      fn {
        system = sys;
        pkgs = pkgsFor sys;
      });

    names = attrNames (fn {
      system = derived;
      pkgs = pkgsFor derived;
    });
  in
    genAttrs names (
      name:
        mapAttrs (_: outputs: outputs.${name}) perSystem
    );
in
  __exports.internal
  // {
    inherit __doc;
    _rootAliases = __exports.external;
  }
