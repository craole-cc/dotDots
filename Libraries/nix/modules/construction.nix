{
  _,
  _default,
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
        mkConfig
        mkConfigurations
        mkUtilities
        mkContext
        mkFlake
        ;
      inherit (_.modules.core.construction) mkCore;
      inherit (_.modules.home.construction) mkHome;
    };
    exports = {
      local = functions;
      store = functions;
    };
  in {
    inherit doc exports functions;
  };

  inherit (_.attrsets.access) attrNames getAttrFromPath;
  inherit (_.attrsets.construction) genAttrs listToAttrs optionalAttrs;
  inherit (_.attrsets.transformation) filterAttrs mapAttrs setAttrByPath;
  inherit (_.debug.assertions) withContext;
  inherit (_.hardware.system) getSystems;
  inherit (_.lists.construction) concatLists optionals;
  inherit (_.lists.predicates) elem;
  inherit (_.schema.construction) mkSchema;
  inherit (_.modules.construction) mkIf mkMerge;
  inherit (_.modules.evaluation) evalModules extend;
  inherit (_.modules.home.users) mkUsers;
  inherit (_.options.construction) mkOption;
  inherit (_.sources.modules) mkModules;
  inherit (_.strings.construction) concat;
  inherit (_.types.combinators) attrsOf submodule;
  inherit (_.types.primitives) anything;

  sourceArgs = {
    paths ? _default.paths,
    host,
    ...
  } @ args:
    import paths.repo.src.store (args // {inherit host;});

  mkFlake = lib: {inherit lib;} // (mkConfigurations lib) // (mkUtilities lib);

  #> Every host whose `class` (default `"nixos"`) matches `class`.
  hostsByClass = {
    hosts,
    class,
  }:
    filterAttrs (_: host: (host.class or "nixos") == class) hosts;

  mkConfigurations = {
    inputs,
    paths,
    top ? _default.names.top or "_",
    ...
  } @ args: let
    # Home is wired again, but Modules/nix/home/default.nix explicitly imports
    # only modules already migrated to the mkContext/mkConfig contract.
    wireHome = true;

    types = let
      of = class:
        hostsByClass {
          inherit (mkSchema {}) hosts;
          inherit class;
        };
    in {
      nixos = of "nixos";
      darwin = of "darwin";
      home = of "home-manager";
    };

    inherit (inputs.home-manager.lib) hm homeManagerConfiguration;
    lib = extend (_self: _super: {inherit hm;});

    # Home Manager owns these module arguments per user/evaluation. Passing
    # host-level values with the same names through extraSpecialArgs masks the
    # submodule values (for example `name = "Victus"` replacing `craole`).
    homeReservedArgs = [
      "config"
      "name"
      "options"
      "pkgs"
      "inputs"
      "paths"
    ];

    #> Per-class module set. `class` is `"nixos"`/`"darwin"` for
    #> `mkSystem`, `"home-manager"` for `mkHomeHost`.
    modulesOf = class: mkModules {inherit class inputs;};

    mkSystem = host: let
      hostArgs = sourceArgs (args // {inherit host;} // host);
      class = host.class or "nixos";
      specialArgs = removeAttrs (hostArgs // {inherit top;}) [
        "config"
        "lib"
      ];
      # `inputs` and `paths` are supplied per user by mkUsers._module.args;
      # reserved Home Manager module arguments must remain owned by HM.
      homeSpecialArgs = removeAttrs (specialArgs // {inherit lib;}) homeReservedArgs;

      classified = modulesOf class;
      core = optionalAttrs wireHome {
        home-manager = {
          extraSpecialArgs = homeSpecialArgs;
          backupFileExtension = "hm-backup";
          overwriteBackup = true;
          useGlobalPkgs = true;
          useUserPackages = true;
          users = mkUsers {
            inherit inputs host;
            modules = classified.home;
          };
        };
      };

      evaluated = evalModules {
        specialArgs =
          specialArgs
          // {
            inherit (classified.all) modulesPath baseModules;
            modules =
              classified
              // {
                host = core;
              };
          };

        modules =
          classified.base
          ++ classified.core
          ++ [core]
          ++ (host.imports or [])
          ++ [paths.repo.mod.default.store]
          ++ [{config._module.args = specialArgs;}];
      };
    in
      if class == "darwin"
      then evaluated // {system = evaluated.config.system.build.toplevel;}
      else evaluated;

    mkManager = name: host: let
      hostArgs = sourceArgs (args // {inherit host;});
      specialArgs = removeAttrs (hostArgs // {inherit lib;}) homeReservedArgs;
      users = let
        specs = mkUsers {
          inherit host inputs;
          modules = (modulesOf "home-manager").home;
          standalone = true;
        };

        primary = let
          names = attrNames specs;
          primaryName = host.users.primary.name or null;
        in
          assert withContext {
            name = "mkHosts";
            context = "resolving the interactive user for host '${name}' (class = \"home-manager\")";
            assertion = primaryName != null && elem primaryName names;
            message = "host.users.primary.name must be set to one of: ${concat ", " names}";
          }; primaryName;

        modules = [specs.${primary}];
      in {
        inherit specs modules;
      };
    in
      homeManagerConfiguration {
        inherit (hostArgs) pkgs;
        inherit (users) modules;
        extraSpecialArgs = specialArgs;
      };
  in
    optionalAttrs (types.nixos != {}) {
      nixosConfigurations =
        mapAttrs (
          name: sys:
            mkSystem (
              sys
              // {
                modules =
                  (sys.modules or [])
                  ++ (lib.optional (name == "default") {
                    fileSystems."/" = {
                      device = "/dev/null";
                      fsType = "ext4";
                    };
                  });
              }
            )
        )
        types.nixos;
    }
    // optionalAttrs (types.darwin != {}) {
      darwinConfigurations = mapAttrs (_: mkSystem) types.darwin;
    }
    // optionalAttrs (wireHome && types.home != {}) {
      homeConfigurations = mapAttrs mkManager types.home;
    };

  mkUtilities = {
    inputs ? {},
    hosts ? schema.hosts or {},
    paths ? _default.paths or {},
    schema ? _default.schema or {},
    ...
  } @ args: let
    systems = getSystems {
      inherit hosts;
      inherit (inputs) nixpkgs;
      inherit (inputs.nixpkgs) legacyPackages;
    };
    inherit (systems) pkgsFor derived all;

    fn = {
      system,
      pkgs,
      host ? null,
    }:
      import paths.repo.mod.global.store (
        args
        // {inherit pkgs system;}
        // optionalAttrs (host != null) {
          inherit host;
          paths = host.paths;
        }
      );

    systemHosts = system:
      filterAttrs (_: host: host.system == system) hosts;

    hostShells = system: let
      matching = systemHosts system;
      pkgs = pkgsFor system;
    in
      listToAttrs (
        concatLists (
          map (
            hostName: let
              host = matching.${hostName};
              outputs = fn {inherit host pkgs system;};
            in
              map
              (shellName: {
                name = "${hostName}-${shellName}";
                value = outputs.devShells.${shellName};
              })
              (attrNames outputs.devShells)
          )
          (attrNames matching)
        )
      );

    representative = fn {
      system = derived;
      pkgs = pkgsFor derived;
    };
  in
    {
      templates = import paths.repo.kit.default.store;
    }
    // genAttrs
    (attrNames representative)
    (
      name:
        if name == "devShells"
        then genAttrs all hostShells
        else
          mapAttrs (_: outputs: outputs.${name}) (
            genAttrs all (
              system:
                fn {
                  inherit system;
                  pkgs = pkgsFor system;
                }
            )
          )
    );

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
    top ? _default.names.top,
    dom,
    sub ? null,
    mod,
    kind ?
      if sub == "core"
      then dom
      else null,
    name ? mod,
  }: let
    derived = rec {
      path =
        [top "resolved" dom]
        ++ (optionals (sub != null) [sub])
        ++ [mod];
      cfg = (getAttrFromPath path config).explicit;
    };

    resolved = rec {
      cfg = getAttrFromPath [top "resolved"] config;
      dom = cfg.${dom} or {};
      ice = cfg.interface or {};

      windowManagers = ice.windowManager or null;
      wm = windowManagers;

      desktopEnvironments = ice.desktopEnvironment or null;
      de = desktopEnvironments;

      panels = ice.panel or null;
      bar = panels;

      hasHyprland =
        (wm == "hyprland")
        || config.programs.hyprland.enable or false
        || config.wayland.windowManager.hyprland.enable or false;

      hasNiri = (wm == "niri") || config.programs.niri.enable or false;

      mkWants = name: value: {condition = value == name;};
      wantsCosmic = mkWants "cosmic" desktopEnvironments;
      wantsDmsShell = mkWants "dms-shell" panels;
      wantsGnome = mkWants "gnome" desktopEnvironments;
      wantsHyprland = mkWants "hyprland" windowManagers;
      wantsNiri = mkWants "niri" windowManagers;
      wantsPlasma = mkWants "plasma" desktopEnvironments;
    };

    ctx = {
      inherit
        config
        derived
        dom
        kind
        mod
        name
        resolved
        sub
        top
        ;
      inherit (derived) path cfg;
      inherit
        (resolved)
        bar
        de
        desktopEnvironments
        hasHyprland
        hasNiri
        ice
        panels
        wantsCosmic
        wantsDmsShell
        wantsGnome
        wantsHyprland
        wantsNiri
        wantsPlasma
        windowManagers
        wm
        ;
    };
  in
    ctx // {inherit ctx;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.store;
  }
