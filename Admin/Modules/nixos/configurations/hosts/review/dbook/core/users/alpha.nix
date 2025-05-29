{ lib, ... }:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) str;

  base = "users";
  mod = "alpha";
in
{
  options.DOTS.${base}.${mod} = {
    name = mkOption {
      description = "The name of the default admin user";
      default = "craole";
      type = str;
    };
    description = mkOption {
      description = "The full name of the default admin user";
      default = "Craig 'Craole' Cole";
      type = str;
    };
    loginAutomatically = mkEnableOption "auto-login" // {
      default = true;
    };
  };
}
