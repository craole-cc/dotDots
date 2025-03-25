{lib, ...}: let
  inherit (lib.types) attrsOf str submodule;
  inherit (lib.options) mkOption;
in {
  options.users = mkOption {
    description = "User configurations";
    type = attrsOf (submodule {
      options = {
        username = mkOption {
          type = str;
        };
        fullname = mkOption {
          type = str;
        };
        email = mkOption {
          type = str;
        };
        sshKey = mkOption {
          type = str;
          description = "SSH public key";
        };
      };
    });
  };
}
