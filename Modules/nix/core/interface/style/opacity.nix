{
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
  inherit (lix.styles.types) opacity;

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

  userPath = "host.users.data.primary.interface.style.opacity";
  mkDefaultText = polarity:
    literalExpression ''
      ${userPath}.${polarity} or { terminal = 0.9; popups = 0.95; }
    '';
  mkDescription = polarity: "Opacity values for the ${polarity} polarity";
  mkPolarityOption = polarity:
    mkOption {
      description = mkDescription polarity;
      default = user.${polarity} or seed.${polarity};
      defaultText = mkDefaultText polarity;
      type = opacity.core;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};
    light = mkPolarityOption "light";
    dark = mkPolarityOption "dark";
  };
}
