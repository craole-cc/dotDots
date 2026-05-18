_: let
  category = "icons";
in {
  "${category}" = {
    candy-icons = {
      names = {
        package = "candy-icons";
        aliases = ["candy"];
      };
      categories = [category];
    };

    papirus = {
      names = {
        package = "papirus-icon-theme";
        aliases = ["papirus-icon-theme"];
      };
      categories = [category];
    };

    papirus-dark = {
      names = {
        package = "papirus-icon-theme";
        aliases = [];
      };
      categories = [category];
      variant = "dark";
    };

    adwaita = {
      names = {
        package = "adwaita-icon-theme";
        aliases = ["adwaita-icon-theme" "gnome"];
      };
      categories = [category];
    };

    hicolor = {
      names = {
        package = "hicolor-icon-theme";
        aliases = [];
      };
      categories = [category];
    };

    numix = {
      names = {
        package = "numix-icon-theme";
        aliases = ["numix-icon-theme"];
      };
      categories = [category];
    };

    numix-circle = {
      names = {
        package = "numix-icon-theme-circle";
        aliases = ["numix-circle-icon-theme"];
      };
      categories = [category];
    };

    tela = {
      names = {
        package = "tela-icon-theme";
        aliases = ["tela-icon-theme"];
      };
      categories = [category];
    };

    tela-circle = {
      names = {
        package = "tela-circle-icon-theme";
        aliases = [];
      };
      categories = [category];
    };

    fluent = {
      names = {
        package = "fluent-icon-theme";
        aliases = ["fluent-icon-theme"];
      };
      categories = [category];
    };

    kora = {
      names = {
        package = "kora-icon-theme";
        aliases = [];
      };
      categories = [category];
    };

    moka = {
      names = {
        package = "moka-icon-theme";
        aliases = [];
      };
      categories = [category];
    };

    faba = {
      names = {
        package = "faba-icon-theme";
        aliases = [];
      };
      categories = [category];
    };
  };
}
