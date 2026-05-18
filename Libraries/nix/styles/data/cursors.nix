_: let
  category = "cursors";
in {
  "${category}" = {
    material = {
      names = {
        package = "material-cursors";
        light = "material_light_cursors";
        dark = "material_dark_cursors";
        aliases = ["material"];
      };
      categories = [category];
    };

    catppuccin = {
      names = {
        package = null;
        aliases = ["catppuccin-cursors"];
      };
      categories = [category];
    };

    bibata-modern-classic = {
      names = {
        package = "bibata-cursors";
        light = "Bibata-Modern-Classic";
        dark = "Bibata-Modern-Classic";
        aliases = ["bibata" "bibata-classic"];
      };
      categories = [category];
    };

    bibata-modern-ice = {
      names = {
        package = "bibata-cursors";
        light = "Bibata-Modern-Ice";
        dark = "Bibata-Modern-Ice";
        aliases = ["bibata-ice"];
      };
      categories = [category];
    };

    bibata-modern-amber = {
      names = {
        package = "bibata-cursors";
        light = "Bibata-Modern-Amber";
        dark = "Bibata-Modern-Amber";
        aliases = ["bibata-amber"];
      };
      categories = [category];
    };

    volantes-light = {
      names = {
        package = "volantes-cursors";
        light = "volantes_light_cursors";
        dark = "volantes_light_cursors";
        aliases = ["volantes-light-cursors"];
      };
      categories = [category];
    };

    volantes-dark = {
      names = {
        package = "volantes-cursors";
        light = "volantes_dark_cursors";
        dark = "volantes_dark_cursors";
        aliases = ["volantes-dark-cursors"];
      };
      categories = [category];
    };

    adwaita = {
      names = {
        package = "adwaita-icon-theme";
        light = "Adwaita";
        dark = "Adwaita";
        aliases = ["adwaita-cursors" "gnome"];
      };
      categories = [category];
    };

    breeze = {
      names = {
        package = "kdePackages.breeze";
        light = "breeze_cursors";
        dark = "breeze_cursors";
        aliases = ["breeze-cursors"];
      };
      categories = [category];
    };
  };
}
