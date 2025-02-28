{ lib, ... }:
let
  dom = "dots";
  mod = "users";
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types)
    attrsOf
    nullOr
    passwdEntry
    str
    submodule
    ;

  # Secure directory for password files
  passwordDir = "/var/lib/dots/passwords";
in
{
  options.${dom}.${mod} = mkOption {
    description = ''Users configuration'';
    default = { };
    type = attrsOf (
      submodule (
        {
          name,
          config,
          ...
        }:
        {
          options = {
            enable = mkEnableOption "Enable user";
            isSystemUser = mkOption {
              description = ''Whether the user is a system user'';
              default = true;
            };
            groups = mkOption {
              description = ''Additional user groups'';
              default = [ "networkmanager" ];
            };
            description = mkOption {
              description = ''User description'';
              default = null;
            };
            password = mkOption {
              type = nullOr (passwdEntry str);
              default = null;
              description = ''Specifies the hashed password for the user.'';
            };
            passwordFile =
              let
                filePath = "${passwordDir}/${name}";
              in
              mkOption {
                type = nullOr str;
                default = "${filePath}";
                description = lib.mdDoc ''
                  Path to the user's hashed password file. By default, this is stored in
                  `${passwordDir}/<username>`.

                  The file will contain a single line with a password hash compatible with
                  `chpasswd -e`. The hash will be in SHA-512 format (`$6$...`).

                  For security:
                  - The directory is created with mode 0700
                  - Password files are created with mode 0400
                  - Both are owned by root:root
                  - The directory is in `/var/lib` which is typically not backed up
                '';
                example = "${filePath}";
              };
            hyprland = {
              enable = mkEnableOption ''Hyprland'' // {
                default = config.isNormalUser;
              };
            };
          };
        }
      )
    );
  };
}
