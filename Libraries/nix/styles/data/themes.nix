_: {
  #  Catppuccin
  catppuccin-latte = {
    aliases = ["latte" "catppuccin-light"];
    categories = ["catppuccin" "light"];
    polarity = "light";
    name = "Catppuccin Latte";
    scheme = "catppuccin-latte";
    package = "catppuccin";
  };

  catppuccin-frappe = {
    aliases = ["frappe" "frappé"];
    categories = ["catppuccin" "dark"];
    polarity = "dark";
    name = "Catppuccin Frappé";
    scheme = "catppuccin-frappe";
    package = "catppuccin";
  };

  catppuccin-macchiato = {
    aliases = ["macchiato"];
    categories = ["catppuccin" "dark"];
    polarity = "dark";
    name = "Catppuccin Macchiato";
    scheme = "catppuccin-macchiato";
    package = "catppuccin";
  };

  catppuccin-mocha = {
    aliases = ["mocha" "catppuccin-dark"];
    categories = ["catppuccin" "dark"];
    polarity = "dark";
    name = "Catppuccin Mocha";
    scheme = "catppuccin-mocha";
    package = "catppuccin";
  };

  #  Rosé Pine
  rose-pine = {
    aliases = ["rosepine" "rose-pine-main"];
    categories = ["rose-pine" "dark"];
    polarity = "dark";
    name = "Rosé Pine";
    scheme = "rose-pine";
    package = "rose-pine-gtk-theme";
  };

  rose-pine-moon = {
    aliases = ["rosepine-moon" "pine-moon"];
    categories = ["rose-pine" "dark"];
    polarity = "dark";
    name = "Rosé Pine Moon";
    scheme = "rose-pine-moon";
    package = "rose-pine-gtk-theme";
  };

  rose-pine-dawn = {
    aliases = ["rosepine-dawn" "pine-dawn" "rose-pine-light"];
    categories = ["rose-pine" "light"];
    polarity = "light";
    name = "Rosé Pine Dawn";
    scheme = "rose-pine-dawn";
    package = "rose-pine-gtk-theme";
  };

  #  Gruvbox
  gruvbox-dark = {
    aliases = ["gruvbox" "gruvbox-hard-dark" "gruvbox-medium-dark"];
    categories = ["gruvbox" "dark"];
    polarity = "dark";
    name = "Gruvbox Dark";
    scheme = "gruvbox-dark-hard";
    package = "gruvbox-gtk-theme";
  };

  gruvbox-light = {
    aliases = ["gruvbox-hard-light" "gruvbox-medium-light"];
    categories = ["gruvbox" "light"];
    polarity = "light";
    name = "Gruvbox Light";
    scheme = "gruvbox-light-hard";
    package = "gruvbox-gtk-theme";
  };

  gruvbox-material-dark = {
    aliases = ["gruvbox-material" "gruvmaterial-dark"];
    categories = ["gruvbox" "dark"];
    polarity = "dark";
    name = "Gruvbox Material Dark";
    scheme = "gruvbox-material-dark-hard";
    package = "gruvbox-gtk-theme";
  };

  gruvbox-material-light = {
    aliases = ["gruvmaterial-light"];
    categories = ["gruvbox" "light"];
    polarity = "light";
    name = "Gruvbox Material Light";
    scheme = "gruvbox-material-light-hard";
    package = "gruvbox-gtk-theme";
  };

  #  Blue Loco
  blueloco-dark = {
    aliases = ["blueloco" "blue-loco-dark"];
    categories = ["blueloco" "dark"];
    polarity = "dark";
    name = "Blue Loco Dark";
    scheme = "blueloco-dark";
    package = null; # not yet in nixpkgs — resolver falls back to stylix scheme only
  };

  blueloco-light = {
    aliases = ["blue-loco-light"];
    categories = ["blueloco" "light"];
    polarity = "light";
    name = "Blue Loco Light";
    scheme = "blueloco-light";
    package = null;
  };

  #  Tokyo Night
  tokyo-night = {
    aliases = ["tokyonight" "tokyo-night-dark"];
    categories = ["tokyo-night" "dark"];
    polarity = "dark";
    name = "Tokyo Night";
    scheme = "tokyo-night-dark";
    package = "tokyo-night-gtk";
  };

  tokyo-night-storm = {
    aliases = ["tokyonight-storm"];
    categories = ["tokyo-night" "dark"];
    polarity = "dark";
    name = "Tokyo Night Storm";
    scheme = "tokyo-night-storm";
    package = "tokyo-night-gtk";
  };

  tokyo-night-light = {
    aliases = ["tokyonight-light" "tokyo-night-day"];
    categories = ["tokyo-night" "light"];
    polarity = "light";
    name = "Tokyo Night Light";
    scheme = "tokyo-night-light";
    package = "tokyo-night-gtk";
  };

  #  Dracula
  dracula = {
    aliases = ["dracula-dark"];
    categories = ["dracula" "dark"];
    polarity = "dark";
    name = "Dracula";
    scheme = "dracula";
    package = "dracula-theme";
  };

  #  Nord
  nord = {
    aliases = ["nordic" "nord-dark"];
    categories = ["nord" "dark"];
    polarity = "dark";
    name = "Nord";
    scheme = "nord";
    package = "nordic";
  };

  nord-light = {
    aliases = ["nordic-light"];
    categories = ["nord" "light"];
    polarity = "light";
    name = "Nord Light";
    scheme = "nord-light";
    package = "nordic";
  };

  #  Everforest
  everforest-dark = {
    aliases = ["everforest"];
    categories = ["everforest" "dark"];
    polarity = "dark";
    name = "Everforest Dark";
    scheme = "everforest-dark-hard";
    package = "everforest-gtk-theme";
  };

  everforest-light = {
    aliases = [];
    categories = ["everforest" "light"];
    polarity = "light";
    name = "Everforest Light";
    scheme = "everforest-light-hard";
    package = "everforest-gtk-theme";
  };

  #  Kanagawa 
  kanagawa = {
    aliases = ["kanagawa-wave"];
    categories = ["kanagawa" "dark"];
    polarity = "dark";
    name = "Kanagawa Wave";
    scheme = "kanagawa";
    package = "kanagawa-gtk-theme";
  };

  kanagawa-dragon = {
    aliases = [];
    categories = ["kanagawa" "dark"];
    polarity = "dark";
    name = "Kanagawa Dragon";
    scheme = "kanagawa-dragon";
    package = "kanagawa-gtk-theme";
  };

  kanagawa-lotus = {
    aliases = ["kanagawa-light"];
    categories = ["kanagawa" "light"];
    polarity = "light";
    name = "Kanagawa Lotus";
    scheme = "kanagawa-lotus";
    package = "kanagawa-gtk-theme";
  };
}
