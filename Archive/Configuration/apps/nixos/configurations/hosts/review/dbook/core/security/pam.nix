{ config, lib, ... }:
let
  inherit (config) DOTS;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;
  inherit (DOTS.interface) users;
  inherit (users.alpha) name;

  base = "security";
  mod = "sudo";
  cfg = DOTS.${base}.${mod};
in
{
  options.DOTS.${base}.${mod} = mkOption {
    description = "The configuration for {{mod}}";
    default = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [ name ];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };

    type = attrs;
  };

  config.${base}.${mod} = cfg;
}
