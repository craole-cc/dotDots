{lib}: let
  inherit
    (lib.attrsets)
    attrNames
    attrValues
    listToAttrs
    mapAttrs
    recursiveUpdate
    ;
  inherit (lib.lists) concatMap;
  inherit
    (lib.packages)
    getSystem
    mkCommon
    mkExtra
    mkFormatting
    mkPkgs
    mkRust
    ;
  inherit
    (lib.shells)
    mkShells
    editorGroups
    editorShellName
    normalizeVariant
    ;
  inherit (lib.templates) deployTemplates;

  #╔═══════════════════════════════════════════════════════════╗
  #║ Tiers                                                     ║
  #╚═══════════════════════════════════════════════════════════╝
  #? Each tier is a raw config attrset.  The caller's `config` is
  #? recursiveUpdate'd on top so flake-level overrides propagate everywhere.
  #? AI is set explicitly per tier; feature tiers leave AI off.

  mkTierRaw = config: tier: recursiveUpdate tier config;
  mkTierVariants = config: let
    tier = mkTierRaw config;
  in {
    #~@ Opinionated tiers
    minimal = tier {
      common = true;
      ai = "minimal";
    };

    default = tier {
      common = true;
      extra = true;
      rust = true;

      ai = "default";
    };

    full = tier {
      rust = true;
      web = true;
      database = true;
      ai = "full";
    };

    #~@ Feature tiers (AI off unless caller overrides)
    rust = tier {
      rust = true;
    };

    rust-web = tier {
      rust = true;
      web = true;
    };

    rust-database = tier {
      rust = true;
      database = true;
    };

    rust-web-database = tier {
      rust = true;
      web = true;
      database = true;
    };

    # web = tier {
    #   web = true;
    # };

    # webDatabase = tier {
    #   web = true;
    #   database = true;
    # };

    # database = tier {
    #   database = true;
    # };
  };

  #╔═══════════════════════════════════════════════════════════╗
  #║ Environment                                               ║
  #╚═══════════════════════════════════════════════════════════╝

  mkEnvironment = {
    inputs,
    self,
    pkgs ? mkPkgs {inherit inputs;},
    config ? {},
    extraPackages ? [],
    extraEnv ? {},
  }: let
    #? Raw tier map — config overrides already baked in
    tierRaws = mkTierVariants config;

    #? Normalized variant map — one per tier
    tierVariants = mapAttrs (_: normalizeVariant) tierRaws;

    #? Build a shell spec from a normalized variant
    mkShellSpec = variant: let
      rust = mkRust {inherit pkgs variant;};
      extra = mkExtra {inherit pkgs variant;};
      common = mkCommon {inherit pkgs variant;};
      packages = extraPackages
        ++ (rust.all or [])
        ++ (extra.all or [])
        ++ (common.all or [])
        ++ (attrValues formatting.packages.${getSystem pkgs});
      env = {}
        // common.env or {}
        // extra.env or {}
        // rust.env or {}
        // extraEnv;
      shellHook = "";
    in {inherit packages env shellHook;};

    #? formatting is variant-agnostic (driven by the default variant)
    formatting = mkFormatting {inherit inputs self;} tierVariants.default;

    #? templates derivation for the default variant (exported for convenience)
    templates = deployTemplates {
      inherit pkgs;
      variant = tierVariants.default;
    };

    #~@ Base shells (one per tier)
    baseShells = mapAttrs (_: mkShellSpec) tierVariants;

    #~@ Editor cross-product shells
    #? Every tier × every editor group → {tierName}With{EditorName}
    editorShells = listToAttrs (
      concatMap
      (
        tierName:
          map
          (editorName: {
            name = editorShellName tierName editorName;
            value = mkShellSpec (
              normalizeVariant (
                recursiveUpdate
                tierRaws.${tierName}
                {editor = editorName;}
              )
            );
          })
          (attrNames editorGroups)
      )
      (attrNames tierRaws)
    );

    #~@ All shells combined
    shells = baseShells // editorShells;
  in {
    inherit templates;
    inherit (formatting) formatter checks;
    devShells = mkShells {inherit inputs shells;};
    packages = listToAttrs (
      map (p: {
        name = p.pname or p.name;
        value = p;
      }) (
        (mkCommon {
          inherit pkgs;
          variant = tierVariants.default;
        }).all
        ++ (mkExtra {
          inherit pkgs;
          variant = tierVariants.default;
        }).all
      )
    );
  };
in {inherit mkEnvironment;}
