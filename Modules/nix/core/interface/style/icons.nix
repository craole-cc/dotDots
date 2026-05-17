{
  host,
  lib,
  lix,
  top,
  ...
}: let
  dom = "interface";
  mod = "style";
  sub = "icons";

  inherit (lib.options) literalExpression mkEnableOption mkOption;
  inherit (lib.types) either package str;
  inherit (lix.style.icons) types;

  user = host.users.data.primary.interface.style.icons or {};
  seed = {
    light = "candy-icons";
    dark = "candy-icons";
  };

  type = either (either str package) types.core;
  userPath = "host.users.data.primary.interface.style.icons";
  example = literalExpression ''
    # as a string (resolved via registry)
    "papirus"

    # as a package
    pkgs.papirus-icon-theme

    # as a resolved attrset
    { name = "papirus"; package = pkgs.papirus-icon-theme; }
  '';

  mkDefaultText = polarity: literalExpression ''${userPath}.${polarity} or "${seed.${polarity}}"'';
  mkDescription = polarity: "Icon theme for the ${polarity} polarity (string, package, or { name, package })";
  mkPolarityOption = polarity:
    mkOption {
      description = mkDescription polarity;
      default = user.${polarity} or seed.${polarity};
      defaultText = mkDefaultText polarity;
      inherit example type;
    };
in {
  options.${top}.${dom}.${mod}.${sub} = {
    enable = mkEnableOption sub // {default = true;};
    light = mkPolarityOption "light";
    dark = mkPolarityOption "dark";
  };
}
