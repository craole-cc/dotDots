{ lib, ... }:
let
  top = "dots";
  mod = "users";

  inherit (lib.options) mkEnableOption;
in
{
  options.${top}.${mod} = {
    craole.enable = mkEnableOption "Craole";
    qyatt.enable = mkEnableOption "Qyatt";
  };
}
