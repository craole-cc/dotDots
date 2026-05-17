{
  config,
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "opacity";

  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lix.types.style) opacity;

  user = host.users.data.primary.interface.style.opacity or {};
  seed = let
    common = {
      terminal = 0.9;
      popups = 0.95;
    };
  in {
    light = common;
    dark = common;
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
      type = opacity.core;
    };

    dark = mkOption {
      description = "Opacity values for the dark polarity";
      default = user.dark or seed.dark;
      defaultText = literalExpression ''
        host.users.data.primary.interface.style.opacity.dark or
          { terminal = 0.9; popups = 0.95; }
      '';
      type = opacity.core;
    };
  };
}
