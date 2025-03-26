{ lib, ... }:
let
  inherit (lib.options) mkOption;
  inherit (lib.types)
    attrsOf
    path
    str
    submodule
    attrs
    ;

  userSubmodule = submodule {
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
        description = ''
          SSH public key
        '';
      };
    };
  };

  hostSubmodule = submodule {
    options = {
      localPath = mkOption {
        type = path;
        description = "Local dotfiles path for this host";
      };
    };
  };
in
{
  imports = [ ../../../config.nix ];
  options = {
    users = mkOption {
      type = attrsOf userSubmodule;
      description = "User configurations";
    };

    hosts = mkOption {
      type = attrsOf hostSubmodule;
      description = "Host-specific configurations";
    };

    paths = mkOption {
      type = attrs;
      description = "System paths calculated from host configurations";
    };
  };
}
