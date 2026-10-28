{lix, ...}: let
  inherit (lix.options.construction) mkFalse mkOption mkStrOption;
  inherit (lix.types.combinators) listOf submodule;
  inherit (lix.types.primitives) str;
  filterType = submodule {
    options = {
      enable = mkFalse "filters";
      # TODO: I always define options with description and default
      name = mkStrOption {type = str;};
      args = mkStrOption {
        type = str;
        default = "";
        description = "Arguments passed to ImageMagick.";
      };
    };
  };
in {
  filters = mkOption {
    type = listOf filterType;
    description = "ImageMagick filters applied randomly to wallpapers.";
    default = [
      {
        name = "Keep original";
        args = "";
      }
      {
        name = "Grayscale";
        args = "-type Grayscale";
      }
      {
        name = "Heavy blur";
        args = "-scale 20% -blur 0x10 -resize 500%";
      }
      {
        name = "Soft blur";
        args = "-scale 20% -blur 0x2 -resize 500%";
      }
      {
        name = "Oil painting";
        args = "-paint 8";
      }
      {
        name = "Pointilism";
        args = "-spread 10 -noise 3";
      }
      {
        name = "Pixellate";
        args = "-scale 3% -scale 3333%";
      }
    ];
  };
}
