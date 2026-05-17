{
  config,
  host,
  lib,
  lix,
  pkgs,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "fonts";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) unique;
  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) listOf package str;
  inherit (lix.modules.core.style) resolveFonts;

  user =
    recursiveUpdate {
      interface.style.fonts = {
        clock = "Rubik";
        emoji = "Noto Color Emoji";
        material = "Material Symbols Sharp";
        monospace = "Maple Mono NF";
        sansSerif = "Monaspace Radon Frozen";
        serif = "Noto Serif";
      };
    }
    (host.users.data.primary or {});

  seed = let
    fonts = user.interface.style.fonts;

    packages = let
      pkgsMap = with pkgs; {
        "Rubik" = [rubik];
        "Maple Mono NF" = [maple-mono.NF-unhinted];
        "Monaspace Radon Frozen" = [monaspace];
        "Victor Mono" = [victor-mono];
        "Noto Serif" = [noto-fonts];
        "Noto Color Emoji" = [noto-fonts-color-emoji];
        "Material Symbols Sharp" = [material-symbols];
        "Material Icons" = [material-icons];
      };

      pkgsFor = name: pkgsMap.${name} or [];

      common = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        material-icons
      ];

      custom = with fonts; (
        []
        ++ pkgsFor clock
        ++ pkgsFor emoji
        ++ pkgsFor Material
        ++ pkgsFor monospace
        ++ pkgsFor sansSerif
        ++ pkgsFor serif
      );

      all = unique (common ++ custom);
    in {inherit all common custom;};
  in
    fonts // {inherit packages;};
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption mod // {default = true;};

    clock = mkOption {
      description = "Clock/UI font";
      default = seed.clock;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.clock or "Rubik"'';
      type = str;
    };

    emoji = mkOption {
      description = "Emoji font";
      default = seed.emoji;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.emoji or "Noto Color Emoji"'';
      type = str;
    };

    material = mkOption {
      description = "Material icons/symbols font";
      default = seed.material;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.material or "Material Symbols Sharp"'';
      type = str;
    };

    monospace = mkOption {
      description = "Monospace font";
      default = seed.monospace;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.monospace or "Maple Mono NF"'';
      type = str;
    };

    sansSerif = mkOption {
      description = "Sans-serif font";
      default = seed.sansSerif;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.sansSerif or "Monaspace Radon Frozen"'';
      type = str;
    };

    serif = mkOption {
      description = "Serif font";
      default = seed.serif;
      defaultText = literalExpression ''host.users.data.primary.interface.style.fonts.serif or "Noto Serif"'';
      type = str;
    };

    packages = mkOption {
      description = "Font packages to install, derived from active font selections";
      default = seed.packages.all;
      defaultText = literalExpression ''
        unique (with seed.packages; (common ++ custom for each of clock, emoji, monospace, sansSerif, serif))
      '';
      type = listOf package;
    };
  };
}
