{ config, lib, ... }:
let
  inherit (config) DOTS;
  inherit (lib.options) mkOption;
  inherit (lib.types) attrs;
  inherit (DOTS.interface) isMinimal;
  inherit (DOTS.users.alpha) name;

  base = "security";
  cfg = DOTS.${base};
in
{
  options.DOTS.${base} = mkOption {
    description = "The configuration for {{mod}}";
    default = {
      pam.services.gdm.enableGnomeKeyring = !isMinimal;
      rtkit.enable = !isMinimal;
      sudo = {
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
    };
    type = attrs;
  };

  config.${base} = cfg;
}
