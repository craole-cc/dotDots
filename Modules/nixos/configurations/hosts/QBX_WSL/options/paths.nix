{ config, lib, ... }:
let
  dom = "dots";
  mod = "alpha";
  # cfg = config.${dom}.${mod};

  inherit (lib.options) mkOption;
  inherit (lib.types) str;
in
{

  options.${dom}.${mod} = {
    name = mkOption {
      description = "The name of the primary user";
      default = "craole";
      type = str;
    };
  };
}
