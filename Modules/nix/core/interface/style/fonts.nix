{
  config,
  host,
  lix,
  pkgs,
  top ? "_",
  ...
}: let
  dom = "interface";
  sub = "style";
  mod = "fonts";

  inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.aggregation) concatMap foldl';
  inherit (lix.lists.transformation) unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) literalExpression mkOption mkTrue;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package str;

  context = mkContext {inherit config dom sub mod top;};

  registry = with pkgs; {
    clock = {
      default = "Rubik";
      packages = {
        "Rubik" = [rubik];
      };
    };

    emoji = {
      default = "Noto Color Emoji";
      packages = {
        "Noto Color Emoji" = [noto-fonts-color-emoji];
      };
    };

    material = {
      default = "Material Symbols Sharp";
      packages = {
        "Material Symbols Sharp" = [material-symbols];
        "Material Icons" = [material-icons];
      };
    };

    monospace = {
      default = "Maple Mono NF";
      packages = {
        "Maple Mono NF" = [maple-mono.NF-unhinted];
        "Victor Mono" = [victor-mono];
      };
    };

    sansSerif = {
      default = "Monaspace Radon Frozen";
      packages = {
        "Monaspace Radon Frozen" = [monaspace];
      };
    };

    serif = {
      default = "Noto Serif";
      packages = {
        "Noto Serif" = [noto-fonts];
      };
    };

    cjk = {
      default = "Noto Sans CJK";
      packages = {
        "Noto Sans CJK" = [noto-fonts-cjk-sans];
      };
    };
  };

  seed = let
    fonts =
      recursiveUpdate (mapAttrs (_: role: role.default) registry)
      (host.users.data.primary.interface.fonts or {});

    packages = let
      pkgsMap = foldl' (acc: role: acc // role.packages) {} (attrValues registry);
    in
      unique (concatMap (name: pkgsMap.${name} or []) (attrValues fonts));
  in
    fonts // {inherit packages;};
in
  mkConfig {
    inherit context;

    options = {
      enable = mkTrue mod;

      clock = mkOption {
        description = "Clock/UI font";
        default = seed.clock;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.clock or "Rubik"'';
        type = str;
      };

      emoji = mkOption {
        description = "Emoji font";
        default = seed.emoji;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.emoji or "Noto Color Emoji"'';
        type = str;
      };

      material = mkOption {
        description = "Material icons/symbols font";
        default = seed.material;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.material or "Material Symbols Sharp"'';
        type = str;
      };

      monospace = mkOption {
        description = "Monospace font";
        default = seed.monospace;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.monospace or "Maple Mono NF"'';
        type = str;
      };

      sansSerif = mkOption {
        description = "Sans-serif font";
        default = seed.sansSerif;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.sansSerif or "Monaspace Radon Frozen"'';
        type = str;
      };

      serif = mkOption {
        description = "Serif font";
        default = seed.serif;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.serif or "Noto Serif"'';
        type = str;
      };

      cjk = mkOption {
        description = "CJK font";
        default = seed.cjk;
        defaultText = literalExpression ''host.users.data.primary.interface.fonts.cjk or "Noto Sans CJK"'';
        type = str;
      };

      packages = mkOption {
        description = "Font packages to install, derived from active font selections";
        default = seed.packages;
        defaultText = literalExpression "unique (concatMap derived from active selections)";
        type = listOf package;
      };
    };

    outputs = with context.cfg; {
      fonts = {
        inherit packages;
        enableDefaultPackages = true;
        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = [monospace];
            sansSerif = [sansSerif];
            serif = [serif];
            emoji = [emoji];
          };
        };
      };

      environment.sessionVariables = {
        FONT_CLOCK = clock;
        FONT_EMOJI = emoji;
        FONT_MATERIAL = material;
        FONT_MONO = monospace;
        FONT_SANS = sansSerif;
        FONT_SERIF = serif;
      };
    };
  }
