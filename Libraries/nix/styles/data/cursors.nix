_: {
  catppuccin = {
    aliases = ["catppuccin-cursors"];
    family = "catppuccin";
    generated = true;
  };

  material = {
    aliases = ["material"];
    family = "material";
    package = "material-cursors";
    polarity = {
      light = {name = "material_light_cursors";};
      dark = {name = "material_dark_cursors";};
    };
  };

  bibata-modern-classic = {
    aliases = ["bibata" "bibata-classic"];
    family = "bibata";
    package = "bibata-cursors";
    name = "Bibata-Modern-Classic";
  };

  bibata-modern-ice = {
    aliases = ["bibata-ice"];
    family = "bibata";
    package = "bibata-cursors";
    name = "Bibata-Modern-Ice";
  };

  bibata-modern-amber = {
    aliases = ["bibata-amber"];
    family = "bibata";
    package = "bibata-cursors";
    name = "Bibata-Modern-Amber";
  };

  volantes-light = {
    aliases = ["volantes-light-cursors"];
    family = "volantes";
    package = "volantes-cursors";
    name = "volantes_light_cursors";
    polarity = "light";
  };

  volantes-dark = {
    aliases = ["volantes-dark-cursors"];
    family = "volantes";
    package = "volantes-cursors";
    name = "volantes_dark_cursors";
    polarity = "dark";
  };

  adwaita = {
    aliases = ["adwaita-cursors" "gnome"];
    family = "adwaita";
    package = "adwaita-icon-theme";
    name = "Adwaita";
  };

  breeze = {
    aliases = ["breeze-cursors"];
    family = "kde";
    package = "kdePackages.breeze";
    name = "breeze_cursors";
  };
}
