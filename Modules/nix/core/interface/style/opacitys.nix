{
  config,
  host,
  lib,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "opacity";
  cfg = config.${top}.${dom}.${mod}.${sub};

  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) float submodule;

  user = host.users.data.primary.interface.style.opacity or {};

  seed = {
    light = {
      terminal = 0.9;
      popups = 0.95;
    };
    dark = {
      terminal = 0.9;
      popups = 0.95;
    };
  };

  polarityType = submodule {
    options = {
      terminal = mkOption {
        description = "Terminal background opacity (0.0-1.0)";
        type = float;
      };
      popups = mkOption {
        description = "Popup/overlay background opacity (0.0-1.0)";
        type = float;
      };
    };
  };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};

    light = mkOption {
      description = "Opacity values for the light polarity";
      default = user.light or seed.light;
      defaultText = literalExpression ''
        host.users.data.primary.interface.style.opacity.light or
          { terminal = 0.9; popups = 0.95; }
      '';
      type = polarityType;
    };

    dark = mkOption {
      description = "Opacity values for the dark polarity";
      default = user.dark or seed.dark;
      defaultText = literalExpression ''
        host.users.data.primary.interface.style.opacity.dark or
          { terminal = 0.9; popups = 0.95; }
      '';
      type = polarityType;
    };
  };
}
