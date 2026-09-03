{
  host,
  lix,
  pkgs,
  top,
  mkConfig,
  ...
}:
let
  dom = "interface";
  mod = "fonts";

  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.lists.transformation) unique;
  inherit (lix.options.construction) literalExpression mkEnableOption mkOption;
  inherit (lix.modules.construction) mkIf;
  inherit (lix.types.combinators) listOf;
  inherit (lix.types.primitives) package str;

  user = recursiveUpdate {
    interface.fonts = {
      clock = "Rubik";
      emoji = "Noto Color Emoji";
      material = "Material Symbols Sharp";
      monospace = "Maple Mono NF";
      sansSerif = "Monaspace Radon Frozen";
      serif = "Noto Serif";
    };
  } (host.users.data.primary or { });

  seed =
    let
      fonts = user.interface.fonts;

      packages =
        let
          pkgsMap = with pkgs; {
            "Rubik" = [ rubik ];
            "Maple Mono NF" = [ maple-mono.NF-unhinted ];
            "Monaspace Radon Frozen" = [ monaspace ];
            "Victor Mono" = [ victor-mono ];
            "Noto Serif" = [ noto-fonts ];
            "Noto Color Emoji" = [ noto-fonts-color-emoji ];
            "Material Symbols Sharp" = [ material-symbols ];
            "Material Icons" = [ material-icons ];
          };

          pkgsFor = name: pkgsMap.${name} or [ ];

          common = with pkgs; [
            noto-fonts
            noto-fonts-cjk-sans
            material-icons
          ];

          custom =
            with fonts;
            (
              [ ]
              ++ pkgsFor clock
              ++ pkgsFor emoji
              ++ pkgsFor material
              ++ pkgsFor monospace
              ++ pkgsFor sansSerif
              ++ pkgsFor serif
            );

          all = unique (common ++ custom);
        in
        {
          inherit all common custom;
        };
    in
    fonts // { inherit packages; };
in
mkConfig {
  inherit dom mod top;

  options = {
    enable = mkEnableOption "fonts" // {
      default = true;
    };

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

    packages = mkOption {
      description = "Font packages to install, derived from active font selections";
      default = seed.packages.all;
      defaultText = literalExpression ''
        unique (with seed.packages; (common ++ custom for each of clock, emoji, material, monospace, sansSerif, serif))
      '';
      type = listOf package;
    };
  };

  outputs =
    ctx:
    let
      inherit (ctx) cfg;
    in
    mkIf cfg.enable {
      fonts = {
        enableDefaultPackages = true;
        packages = cfg.packages;

        fontconfig = {
          enable = true;
          defaultFonts = {
            monospace = [ cfg.monospace ];
            sansSerif = [ cfg.sansSerif ];
            serif = [ cfg.serif ];
            emoji = [ cfg.emoji ];
          };
        };
      };

      environment.sessionVariables = {
        FONT_CLOCK = cfg.clock;
        FONT_EMOJI = cfg.emoji;
        FONT_MATERIAL = cfg.material;
        FONT_MONO = cfg.monospace;
        FONT_SANS = cfg.sansSerif;
        FONT_SERIF = cfg.serif;
      };
    };
}
