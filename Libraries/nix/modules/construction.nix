{
  _,
  _defaults,
  ...
}: let
  meta = let
    doc = ''
      Module Evaluation and System Generation

      Provides the orchestration layer for turning discovered hosts, resolved
      flake inputs, generated package sets, and assembled module lists into
      fully evaluated system configurations.

      This file is responsible for three major tasks:

      1. Evaluating NixOS/Darwin host systems via `evalModules` (`mkSystems`).
      2. Evaluating standalone Home Manager hosts via
         `home-manager.lib.homeManagerConfiguration` (`mkHomes`).
      3. Composing both into the final host-derived flake outputs (`mkHosts`),
         and generating per-system flake-style output matrices (`mkFlake`).

      ## Host routing

      Every host in `schema.hosts` declares a `class` (default `"nixos"`).
      `class` decides which builder owns the host and, in turn, which
      top-level flake output it lands under:

        class            | builder     | output key
        -----------------|-------------|----------------------
        "nixos" (default)| mkSystems   | nixosConfigurations
        "darwin"         | mkSystems   | nixosConfigurations * #TODO: We need darwinConfigurations
        "home-manager"   | mkHomes     | homeConfigurations

      * Darwin hosts still flow through `mkSystems`/`evalModules` today - see
        the `class == "darwin"` branch there for the `system.build.toplevel`
        exposure. A dedicated `darwinConfigurations` output is a natural
        follow-up once `nix-darwin`'s own top-level builder is wired in the
        same way `mkHomes` wires `homeManagerConfiguration`.

      `mkSystems` and `mkHomes` each filter `schema.hosts` down to the hosts
      they own, so a host only ever appears under exactly one output. Neither
      function needs to know the other exists - `mkHosts` is the only place
      that composes them, and `flake.nix` never sees the split at all.
    '';
    functions = {
      inherit
        mkFlake
        mkCore
        mkHome
        mkConfigurations
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
  inherit (_.attrsets.construction) genAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.debug.assertions) withContext;
  inherit (_.filesystem.tree) mkTree;
  inherit (_.hardware.system) getSystems;
  inherit (_.lists.construction) optionals;
  inherit (_.lists.predicates) elem;
  inherit (_.schema.construction) mkSchema;
  inherit (_.modules.construction) mkIf mkMerge;
  inherit (_.modules.evaluation) evalModules extend;
  inherit (_.modules.home.users) mkUsers;
  inherit (_.options.construction) mkOption;
  inherit (_.sources.modules) mkModules;
  inherit (_.sources.packages) mkAll mkPackages;
  inherit (_.strings.construction) concat;
  inherit (_.types.combinators) attrsOf submodule;
  inherit (_.types.primitives) anything;

  /**
  The single entry point `flake.nix` calls. Takes the raw `flake` (`self`)
  and the already-bootstrapped `src` (the result of `import ./. {inherit
  flake lib;}`), and owns everything downstream: assembling `args`, the
  `lib`/`templates` outputs, every host-derived output (via `mkHosts`), and
  the per-system output matrix (`packages.<system>.*`, `devShells.<system>.*`,
  etc.) driven by `fn`.

  This intentionally makes `mkFlake` couple to `dotDots`'s specific `args`/
  `flake'` shape rather than staying a generic per-system-fanout utility -
  that coupling is the whole point: it's what lets `flake.nix` shrink to
  wiring `{flake, src}` in and nothing else. A repo wanting a portable,
  repo-agnostic per-system fanout should reach for the transpose logic
  inlined below directly, not this function.

  ## `args` assembly

  Replicates the two-pass fixed-point `flake.nix` used to build inline:
  `mkAll {inherit flake;}` is merged over `src` to get a first-pass `args`
  (enough to read `names`/`paths` off it), then `flake` is re-derived with
  `name`/`path`/`home` attached from that first pass, and `args` is rebuilt
  a second time with the enriched `flake` folded back in. Downstream
  consumers (host builders, `mkHosts`, module `specialArgs`) read
  `flake.name`/`flake.path`/`flake.home`, so this fixed-point has to survive
  the move into `mkFlake` unchanged.

  TODO: once this is confirmed working end-to-end, revisit whether the
  two-pass fixed-point is still load-bearing or was circumstantial plumbing
  that can simplify now that it's no longer sitting directly in `flake.nix`.

  ## `lib` output

  `nix flake check` warns on unrecognized top-level output names; `args`
  itself isn't a recognized name, so the full `args` attrset is exposed
  under the accepted alias `lib` instead. This is not a curated "just the
  library" export - it is `args`, unchanged, under a name the checker
  accepts.

  ## `tree`

  `src.tree` is the plain, unextended tree - `templates` and `fn` both only
  need static store locations (`tree.kit.nix.store`, `tree.mod.global.store`),
  not the per-host `local` extension `mkSystems`/`mkHomes` each compute via
  `tree // {local = tree.mkLocal flake.path;}` for their own host-scoped
  needs. `mkFlake` never builds that extension itself; it flows through to
  `mkHosts` via `args` and is expected to remain host-scoped there.

  # Args:
    flake: The evaluated flake (`self`), before `dotDots`-specific enrichment.
    src: The bootstrapped source tree (`import ./. {inherit flake lib;}`),
      providing `lix`, `tree`, and everything `mkAll`/`mkHosts` need.
    nixpkgs: Optional nixpkgs input, forwarded to `getSystems`.
    legacyPackages: Optional pre-evaluated legacy package attrset.
    system: Preferred system to use for deriving per-system output names.

  # Returns:
    The complete flake outputs attrset: `lib`, `templates`,
    `nixosConfigurations`, `homeConfigurations`, and every per-system output
    group `fn` produces (`packages.<system>.*`, `devShells.<system>.*`, ...).
  */
  mkFlake = {
    flake,
    src,
    ...
  } @ extra: let
    #> `flake` enriched with the name/path/home fields host builders and
    #> module specialArgs expect at `flake.name`/`flake.path`/`flake.home`.
    flake' = let
      #> First pass: enough of `args` to read `names`/`paths` for enrichment.
      default = src // extra // (mkAll {inherit flake;});
      extended = {
        args = default;
        name = args.names.flake;
        path = args.paths.flake.store;
        home = args.paths.flake.local;
      };
    in
      default // extended;

    #> Second pass: `args` rebuilt with the enriched `flake` folded back in.
    #> `tree` is read off this final `args`, not off `src` directly - `src`
    #> is only the pre-enrichment bootstrap value, and using it here would
    #> mean `fn`/`templates` below silently work off stale data whenever
    #> `args`' tree diverges from `src`'s (e.g. once host-derived path
    #> extensions land, which is exactly the case this file exists to add).
    args = flake'.args // {flake = flake';};
    inherit (args) tree;
  in
    {
      lib = args;
      templates = import tree.kit.nix.store;
    }
    // (mkConfigurations args)
    // (mkUtilities args);

  #> Every host whose `class` (default `"nixos"`) matches `class`.
  hostsByClass = {
    schema ? mkSchema {inherit tree;},
    tree ? mkTree {},
    hosts ? schema.hosts or {}, # TODO: We just need mkSchema and mkTree to get hosts
    class ? null,
  }:
    filterAttrs (_: host: (host.class or "nixos") == class) hosts;

  /**
  Evaluate every host in `schema.hosts` into its class-appropriate
  top-level flake output.

  Every host declares a `class` (default `"nixos"`), which decides both
  which builder below evaluates it and which output key it lands under:

    class            | output key           | builder
    -----------------|----------------------|-------------
    "nixos" (default)| nixosConfigurations  | mkSystem
    "darwin"         | nixosConfigurations *| mkSystem
    "home-manager"   | homeConfigurations   | mkHomeHost

  * Darwin hosts still land under `nixosConfigurations` today - see the
    `class == "darwin"` branch in `mkSystem` for the `system.build.toplevel`
    exposure. A dedicated `darwinConfigurations` output, routed through
    nix-darwin's own top-level builder instead of piggybacking on the
    NixOS eval here, is the natural follow-up - at that point it's a third
    local builder and a third `filterAttrs`/`mapAttrs` pair below, nothing
    else in this file needs to change.

  `mkSystem` and `mkHomeHost` are deliberately not exposed outside this
  function - callers only ever need the merged result, never a single
  class's builder in isolation.

  # Args:
    flake: The evaluated flake (name/path/home derived from it).
    inputs: Canonically resolved flake inputs.
    paths: The resolved path tree.
    libraries: The assembled internal library set.
    names: Canonical name registry (flake/lib/top/...).
    stems: Per-host tree stems, extended per host by `mkTree'`.
    schema: Discovered host/user schema; `schema.hosts` is consumed here.
    extraArgs: Extra arguments merged into each host's special args.

  # Returns:
    `{ nixosConfigurations = {...}; homeConfigurations = {...}; }`
  */
  mkConfigurations = {
    flake,
    inputs,
    paths,
    libraries,
    names,
    stems,
    schema,
    extraArgs ? {},
    ...
  } @ args: let
    inherit (inputs.home-manager.lib) homeManagerConfiguration;

    #> Per-host repository tree - identical construction for every class.
    treeOf = host:
      mkTree {
        stems = stems // {host = host.paths or {};};
        roots = {
          user = paths.home.local;
          xdg = paths.home.local;
          host = flake.path;
        };
      };

    #> Per-host resolved package set - identical call for every class;
    #> each builder below pulls whichever field it needs (`.nixpkgs` for
    #> evalModules-based classes, `.pkgs` for home-manager's standalone
    #> builder).
    packagesOf = host: mkPackages {inherit host inputs;};

    #> Per-class module set. `class` is `"nixos"`/`"darwin"` for
    #> `mkSystem`, `"home-manager"` for `mkHomeHost`.
    modulesOf = class: mkModules {inherit class inputs;};

    #> The special-args shape every class forwards into its module
    #> system, modulo the class-specific extras (`mkSystem` additionally
    #> needs `class`/`flake`; `mkHomeHost` needs neither).
    mkSpecialArgs = {extra ? {}}:
      removeAttrs args ["lib"]
      // extra
      // extraArgs;

    /**
    Evaluate a single `nixos`/`darwin` host through `evalModules`. Darwin
    hosts additionally expose the built system derivation under `system`
    for easier downstream consumption - mirroring what `nix-darwin`'s own
    `darwinSystem` wrapper does, without depending on that wrapper.

    # Args:
      host: The enriched host definition being evaluated.

    # Returns:
      The evaluated module config for `host`, with `system` added when
      `host.class == "darwin"`.
    */

    /**
    Evaluate a single `nixos`/`darwin` host through `evalModules`. Darwin
    hosts additionally expose the built system derivation under `system`
    for easier downstream consumption - mirroring what `nix-darwin`'s own
    `darwinSystem` wrapper does, without depending on that wrapper.

    # Args:
      host: The enriched host definition being evaluated.

    # Returns:
      The evaluated module config for `host`, with `system` added when
      `host.class == "darwin"`.
    */
    mkSystem = host: let
      class = host.class or "nixos";
      tree = treeOf host;
      specialArgs = mkSpecialArgs {
        inherit host tree;
        extra = {inherit class flake;};
      };
      modules = let
        classified = modulesOf class;
        core = mkCore {
          inherit modules host specialArgs tree inputs;
          inherit (packagesOf host) nixpkgs;
        };
      in
        evalModules {
          specialArgs =
            specialArgs
            // {
              inherit (modules.all) modulesPath baseModules;
              modules = classified // {host = core;};
            };
          modules =
            classified.base
            ++ classified.core
            ++ core
            ++ (host.imports or [])
            ++ [tree.store.mod.core]
            ++ [{config._module.args = specialArgs;}];
        };
    in
      if class == "darwin"
      then modules // {system = modules.config.system.build.toplevel;}
      else modules;

    /**
    Evaluate a single `home-manager`-class host through
    `home-manager.lib.homeManagerConfiguration`.
    */
    mkManager = name: host: let
      tree = treeOf host;
      users = let
        specs = mkUsers {
          inherit host inputs tree;
          modules = (modulesOf "home-manager").home;
          standalone = true;
        };

        primary = let
          names = attrNames specs;
        in
          assert withContext {
            name = "mkHosts";
            context = "resolving the interactive user for host '${name}' (class = \"home-manager\")";
            assertion = host ? primaryUser && elem host.primaryUser names;
            message = "host.primaryUser must be set to one of: ${concat ", " names}";
          };
            host.primaryUser;

        modules = [specs.${primary}];
      in {inherit specs modules;};
    in
      homeManagerConfiguration {
        inherit (packagesOf host) pkgs;
        extraSpecialArgs = mkSpecialArgs {inherit host tree;};
        inherit (users) modules;
      };

    hostOf = class:
      hostsByClass {
        inherit (schema) hosts;
        inherit class;
      };
  in {
    nixosConfigurations = mapAttrs (_: mkSystem) (hostOf "nixos");
    darwinConfigurations = mapAttrs (_: mkSystem) (hostOf "darwin");
    homeConfigurations = mapAttrs mkManager (hostOf "home-manager");
  };

  mkUtilities = {
    flake,
    inputs,
    paths,
    ...
  } @ args: let
    systems = getSystems {
      inherit flake;
      inherit (inputs) nixpkgs;
      inherit (inputs.nixpkgs) legacyPackages;
      # system
      inherit (mkSchema paths) hosts;
    };
    inherit (systems) pkgsFor derived all;

    fn = {
      system,
      pkgs,
    }:
      import paths.mod.global.store (args // {inherit pkgs system;});

    perSystem = (genAttrs all) (
      sys: let
      in
        fn {
          system = sys;
          pkgs = pkgsFor sys;
        }
    );

    perSystemNames = attrNames (fn {
      system = derived;
      pkgs = pkgsFor derived;
    });
  in
    genAttrs
    perSystemNames
    (name: mapAttrs (_: outputs: outputs.${name}) perSystem);

  /**
  Build the host-specific core module list used during system evaluation.

  Produces the base module stack for a host by combining low-level hardware,
  networking, environment, services, programs, users, and home-manager glue.
  The result is returned as a module list suitable for `evalModules`.

  # Args:
  `host`
  :The enriched host definition.

  `nixpkgs`
  :The resolved nixpkgs source/configuration attrset.

  `inputs`
  :Canonically resolved flake inputs.

  `modules`
  :Resolved input-provided module sets.

  `specialArgs`
  :Extra arguments forwarded into module evaluation.


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
  Produce the complete Home Manager option block for the current host, to be
  nested under `home-manager.users.<name>` inside a NixOS/Darwin eval.

  Configures Home Manager to reuse the system package set, forward shared
  special arguments, and generate per-user configurations through the
  home user builder. This is the NixOS-embedded counterpart to `mkHomes`
  above - `mkHomes` builds standalone `homeConfigurations` entries with no
  parent NixOS eval at all, while this builds the `home-manager = {...}`
  fragment consumed by `mkCore`/`mkSystems`.

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
    paths,
  }: let
    lib =
      extend
      (_self: _super: {inherit (inputs.home-manager.lib) hm;});
  in {
    home-manager = {
      backupFileExtension = "backup";
      overwriteBackup = true;
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = specialArgs // {inherit lib;};
      users = mkUsers {inherit host inputs modules paths;};
    };
  };

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
      else cfg.enable or true;
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
    top ? _defaults.top,
    dom,
    sub ? null,
    mod,
    kind ?
      if sub == "core"
      then dom
      else null,
    name ? mod,
  }: let
    path = mkPath {inherit top dom sub mod;};
  in
    {inherit config top dom sub mod path kind name;}
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
