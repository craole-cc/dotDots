{
  _,
  names,
  ...
}: let
  meta = let
    doc = ''
      Module Evaluation and System Generation

      Provides the orchestration layer for turning discovered hosts, resolved
      flake inputs, generated package sets, and assembled module lists into
      fully evaluated system configurations.

      This file is responsible for two major tasks:

      1. Evaluating host systems via `evalModules`.
      2. Generating per-system flake-style output matrices from a function.
    '';
    functions = {
      inherit
        mkSystems
        mkFlake
        mkCore
        mkHome
        mkTree
        mkConfig
        mkContext
        ;
    };
    exports = {
      local = functions;
      store = functions;
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrNames getAttrFromPath;
  inherit (_.attrsets.construction) genAttrs optionalAttr;
  inherit (_.attrsets.transformation) mapAttrs setAttrByPath;
  inherit (_.filesystem.tree) mkTree;
  inherit (_.hardware.system) getSystems;
  inherit (_.lists.construction) optionals;
  inherit (_.modules.evaluation) evalModules extend;
  inherit (_.modules.construction) mkIf mkMerge;
  inherit (_.modules.home.users) mkUsers;
  inherit (_.options.construction) mkOption;
  inherit (_.sources.modules) mkModules;
  inherit (_.sources.packages) mkPackages;
  inherit (_.types.combinators) attrsOf submodule;
  inherit (_.types.primitives) anything;

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
    paths,
    libraries,
    names,
    tree,
    schema,
    extraArgs ? {},
    ...
  }:
    mapAttrs (
      _: host: let
        src = {
          path = host.paths.src or (paths.src.local or null);
          name = names.src;
        };

        class = host.class or "nixos";
        tree' = tree // {local = tree.mkLocal src.path;};

        specialArgs =
          {
            inherit host class inputs src;
            inherit (names) top;
            "${names.lib}" = libraries.${names.lib};
            tree = tree';
          }
          // extraArgs;

        flakeArgs = let
          packages = mkPackages {inherit host inputs;};
          modules = mkModules {inherit class inputs;};
        in {inherit inputs packages modules;};

        moduleArgs = let
          fromInputs = flakeArgs.modules;
          fromHost = mkCore {
            inherit host specialArgs;
            inherit (flakeArgs) modules inputs;
            inherit (flakeArgs.packages) nixpkgs;
            tree = tree';
          };
          fromEval = evalModules {
            specialArgs =
              specialArgs
              // {
                inherit (fromInputs.all) modulesPath baseModules;
                modules = fromInputs // {host = fromHost;};
              };
            modules =
              fromInputs.base
              ++ fromInputs.core
              ++ fromHost
              ++ (host.imports or [])
              ++ [tree'.store.mod.core]
              ++ [{config._module.args = specialArgs;}];
          };
        in {
          inherit fromInputs fromHost fromEval;
        };
      in
        if class == "darwin"
        then
          moduleArgs.fromEval
          // {system = moduleArgs.fromEval.config.system.build.toplevel;}
        else moduleArgs.fromEval
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
    {
      nixpkgs = {
        flake.source = nixpkgs.outPath;
        config.allowUnfree = host.packages.allowUnfree or true;
      };
    }
    (mkHome {
      inherit host specialArgs tree inputs;
      modules = modules.home;
    })
  ];

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
      backupFileExtension = "backup";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs =
        specialArgs
        // {
          lib = extend (_self: _super: {
            hm = inputs.home-manager.lib.hm or {};
          });
        };
      users = mkUsers {inherit inputs modules host tree;};
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
  mkFlake = {
    flake ? {},
    nixpkgs ? {},
    legacyPackages ? {},
    system ? null,
    hosts ? {},
    fn,
  }: let
    systems = getSystems {
      inherit flake nixpkgs legacyPackages system hosts;
    };
    inherit (systems) pkgsFor derived all;

    perSystem = (genAttrs all) (
      sys:
        fn {
          system = sys;
          pkgs = pkgsFor sys;
        }
    );

    names = attrNames (fn {
      system = derived;
      pkgs = pkgsFor derived;
    });
  in
    genAttrs names (name: mapAttrs (_: outputs: outputs.${name}) perSystem);

  mkConfig = {
    predicate ? null,
    outputs,
    options ? {},
    context,
  }: let
    inherit (context) path cfg top;
    condition =
      if predicate != null
      then predicate
      else cfg.enable;
    resolved = mkIf condition outputs;
  in {
    options = setAttrByPath path {
      explicit = options;
      implicit = mkOption {
        type = submodule {freeformType = attrsOf anything;};
        default = {};
      };
    };
    config = mkMerge [
      resolved
      {${top}.outputs = resolved;}
      (setAttrByPath (path ++ ["implicit"]) resolved)
    ];
  };

  mkContext = {
    config,
    top ? names.top,
    dom,
    sub ? null,
    mod,
    kind ?
      if sub == "core"
      then dom
      else null,
    name ? mod,
    user ? null,
    pkgs ? null,
  }: let
    path = mkPath {inherit top dom sub mod;};
  in
    {inherit config top dom sub mod path kind name;}
    // optionalAttr "user" user
    // optionalAttr "pkgs" pkgs
    // {cfg = (getAttrFromPath path config).explicit;};
  mkPath = {
    top,
    dom,
    sub,
    mod,
  }:
    [top "resolved" dom]
    ++ (optionals (sub != null) [sub])
    ++ [mod];
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }
