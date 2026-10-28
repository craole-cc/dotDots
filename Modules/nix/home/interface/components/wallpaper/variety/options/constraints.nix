{lix, ...}: let
  inherit (lix.options.construction) mkFalse mkIntOption mkTrue mkStrOption;
in {
  constraints = {
    desiredColor = {
      enable = mkFalse "Variety desired color enabled.";

      value = mkStrOption {
        default = "160 160 160";
        description = "Variety desired color.";
      };
    };

    minSize = {
      enable = mkTrue "Variety min size enabled.";
      value = mkIntOption {
        default = 100;
        description = "Variety min size.";
      };
    };

    landscape = {
      enable = mkTrue "Variety use landscape enabled.";
    };

    lightness = {
      enable = mkFalse "Variety lightness enabled.";

      mode = mkIntOption {
        default = 0;
        description = "Variety lightness mode.";
      };
    };

    minRating = {
      enable = mkFalse "Variety min rating enabled.";
      value = mkIntOption {
        default = 4;
        description = "Variety min rating.";
      };
    };

    nameRegex = {
      enable = mkFalse "Variety name regex enabled.";
      value = mkStrOption {
        default = ".*";
        description = "Variety name regex.";
      };
    };
  };
}
