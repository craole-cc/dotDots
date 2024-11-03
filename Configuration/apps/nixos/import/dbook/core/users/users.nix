{ config, lib,... }:
let
  inherit (config) DOTS;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrsOf attrs;
  inherit (DOTS.${base}.alpha) name description;

  base = "users";
  mod = "users";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "The users that should been activated";
    default =
      {
        ${name} = {
          isNormalUser = true;
          inherit description;
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };
      };
    type = attrsOf attrs;
  };

  config.${base}.${mod} = cfg;
}
