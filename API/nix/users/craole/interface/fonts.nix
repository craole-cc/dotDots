{
  fonts = let
    #~@ Constants
    size = {
      text = 11;
      symbol = 12;
      display = 96;
    };

    style = {
      regular = "Regular";
      bold = "Bold";
    };

    #~@ Helpers
    #? A font family: its display name and the nixpkgs package providing it
    mkFamily = name: package: {inherit name package;};

    #? The Nerd Font build of a family
    mkNF = font: mkFamily "${font.name} Nerd Font" "nerd-fonts.${font.package}";

    #? A mono family paired with its Nerd Font build
    mkMono = name: package: let
      mono = mkFamily name package;
    in {
      inherit mono;
      monoNF = mkNF mono;
    };

    #? Attach size and style to a family
    mkFont = font: overrides:
      font
      // {
        size = overrides.size or size.text;
        style = overrides.style or style.regular;
      };

    #? One variant (sans, serif, monoNF...) of a family at the default size and style
    mkVariant = variant: font: mkFont font.${variant} {};

    #~@ Families
    cinzel = let
      package = "cinzel";
    in {
      serif = mkFamily "Cinzel" package;
      display = mkFamily "Cinzel Decorative" package;
    };

    fira = let
      mk = variant: suffix: mkFamily "Fira ${variant}" "fira-${suffix}";
      mono = mk "Code" "code";
    in {
      inherit mono;
      monoNF = mkNF mono;
      math = mk "Math" "math";
      sans = mk "Sans" "sans";
    };

    ibm = let
      mk = variant: mkFamily "IBM Plex ${variant}" "ibm-plex";
    in {
      mono = mk "Mono";
      math = mk "Math";
      sans = mk "Sans";
      serif = mk "Serif";
    };

    # jetbrains = mkMono "JetBrains Mono" "jetbrains-mono";

    lilex = mkMono "Lilex" "lilex";

    maple = {
      mono = mkFamily "Maple Mono" "maple-mono";
      #? Unhinted NF build rather than the generic nerd-fonts.<name> package
      monoNF = mkFamily "Maple Mono NF" "maple-mono.NF-unhinted";
    };

    material = let
      mk = variant:
        mkFont (mkFamily "Material Symbols ${variant}" "material-symbols") {size = size.symbol;};
    in {
      outlined = mk "Outlined";
      rounded = mk "Rounded";
      sharp = mk "Sharp";
    };

    # monaspace = let
    #   mk = name: mkFamily "Monaspace ${name}" "monaspace";
    # in {
    #   sans = mk "Neon"; #? Classic neo-grotesque sans-serif
    #   humanist = mk "Argon"; #? Humanist sans-serif with a warm feel
    #   serif = mk "Xenon"; #? Wedge-serif / slab hybrid style
    #   math = mk "Radon"; #? Cursive, expressive script-like variant
    #   square = mk "Krypton"; #? Sharp, mechanical square-sans aesthetic
    # };

    orbitron = let
      font = mkFamily "Orbitron" "orbitron";
    in {
      sans = font;
      display = font;
    };

    #~@ Categories
    categories = {
      display = let
        mk = font:
          mkFont font.display {
            size = size.display;
            style = style.bold;
          };
      in [
        (mk cinzel)
        (mk orbitron)
      ];

      material = with material; [outlined rounded sharp];

      math = let
        mk = mkVariant "math";
      in [
        (mk fira)
      ];

      monospace = let
        mk = mkVariant "monoNF";
      in [
        (mk lilex)
        (mk maple)
        (mk fira)
        # (mk jetbrains)
      ];

      sans = let
        mk = mkVariant "sans";
      in [
        (mk ibm)
        (mk fira)
        (mk orbitron)
      ];

      serif = let
        mk = mkVariant "serif";
      in [
        (mk ibm)
        (mk cinzel)
      ];

      square = let
        mk = mkVariant "display";
      in [
        (mk cinzel)
        (mk orbitron)
      ];
    };
  in
    categories;
}
