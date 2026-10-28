{
  lix,
  paths,
  style,
  ...
}: let
  inherit (lix.options.construction) mkIntOption mkOption mkStrOption mkTrue;
in {
  quotes = {
    enable = mkTrue "Variety quotes";
    font = mkStrOption {
      default = "${style.fonts.serif} 30";
      description = "Font family and size used for wallpaper quotes.";
    };
    text.color = mkStrOption {
      default = "255 255 255";
      description = "Variety quotes text color.";
    };
    background.color = mkStrOption {
      default = "80 80 80";
      description = "Variety quotes bg color.";
    };
    background.opacity = mkIntOption {
      default = 55;
      description = "Variety quotes bg opacity.";
    };
    text.shadow = mkTrue "Variety quotes text shadow";
    width = mkIntOption {
      default = 70;
      description = "Variety quotes width.";
    };
    position.horizontal = mkIntOption {
      default = 100;
      description = "Variety quotes hpos.";
    };
    position.vertical = mkIntOption {
      default = 40;
      description = "Variety quotes vpos.";
    };
    maxLength = mkIntOption {
      default = 250;
      description = "Variety quotes max length.";
    };

    disabledSources = mkStrOption {
      default = "Urban Dictionary";
      description = "Variety quotes disabled sources.";
    };

    tags = mkStrOption {
      default = "";
      description = "Variety quotes tags.";
    };

    authors = mkStrOption {
      default = "";
      description = "Variety quotes authors.";
    };

    change = {
      enable = mkTrue "Variety quotes change enabled";
      interval = mkIntOption {
        default = 300;
        description = "Variety quotes change interval.";
      };
    };

    preferred = {
      file = mkStrOption {
        default = paths.variety.files.quotes;
        description = "File for preferred quotes.";
      };
      format = mkStrOption {
        default = "fortune";
        description = "Format for preferred quotes.";
      };
    };
  };
}
