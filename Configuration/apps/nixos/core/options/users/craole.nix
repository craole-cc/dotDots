{ config, lib, ... }:
let
  #| Native Imports
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types)
    listOf
    nullOr
    int
    passwdEntry
    str
    attrs
    ;

  #| Extended Imports
  inherit (config) DOTS system;
  base = "users";
  mod = "craole";
  cfg = DOTS.${base}.${mod};

in
{
  options.DOTS.${base}.${mod} = {
    enable = mkEnableOption "Initialize the user account for {{mod}}";

    isNormalUser = mkEnableOption // {
      description = "Allow the user to login";
      default = true;
    };

    isAdmin = mkEnableOption // {
      description = "Allow the user to perform administrative tasks";
      default = true;
    };

    name = mkOption {
      description = "The name of the user account.";
      default = mod;
      type = passwdEntry str;
      apply =
        x:
        assert (
          builtins.stringLength x < 32
          || abort "Username '${x}' is longer than 31 characters which is not allowed!"
        );
        x;
    };

    uid = mkOption {
      description = "The unique id number withing the range of `1000` to `59999`";
      default = 1551;
      type = nullOr int;
    };

    hashedPassword = mkOption {
      description = "Use `mkpasswd` to generate a hash of the user's password";
      default = "$y$j9T$2/KP4Wdc085m.udldFeHA0$C8K1uEH1hBwM0SHXg5l2Rnvy3jGEnq/p0MN7O7ZIXw3";
      type = nullOr (passwdEntry str);
    };

    description = mkOption {
      type = str;
      default = "Craig 'Craole' Cole";
      description = "User's description";
    };

    extraGroups = mkOption {
      description = "The user's auxiliary groups.";
      default = [
        "wheel"
        "networkmanager"
      ];
      type = listOf str;
    };

    git = {
      name = mkOption {
        type = str;
        default = "Craole";
        description = "Git username";
      };
      email = mkOption {
        type = str;
        default = "32288735+Craole@users.noreply.github.com";
        description = "Git enail";
      };
      sshKey = mkOption {
        type = str;
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBNIEMrsteaXwEydURdn+qCQ0JIGeqwDmlddsDc5MjQ";
        description = "Git ssh key";
      };
    };

    ssh = mkOption {
      description = "SSH configuration";
      type = attrs;
      default = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZLZzDkJWWwfVOCiOZzZ0wkcbIyu6sSRktila4YiT5w";
        age = "age12a8xzr4zkeq0cx5qywjgxydpj6k2sqdeznqnxwjdv4puuxvyqscsgz22yg";
      };
    };

    paths = mkOption {
      description = "The important paths for the {{mod}}";
      default = rec {
        config = ./. + "/${mod}.nix";
        homeDirectory = "/home/${mod}";
        toLink = [ ];
        media = rec {
          default = homeDirectory;
          pictures = default + "/Pictures";
          wallpaper = "${pictures}/Wallpapers";
          music = default + "/Music";
          videos = rec {
            default = homeDirectory + "/Videos";
            movies = default + "/Movies";
            tv = default + "/TV";
          };
        };
        downloads = rec {
          default = homeDirectory + "/Downloads";
          tutorials = default + "/Tutorials";
          books = default + "/Books";
          research = default + "/Dotfiles";
        };
        projects = rec {
          default = homeDirectory + "/Projects";
          ruby = default + "/Ruby";
          rust = default + "/Rust";
        };
      };
      type = attrs;
    };

  };

  # config = mkIf cfg.enable {
    # users.users.${cfg.name} = {
    #   inherit (cfg)
    #     description
    #     uid
    #     isNormalUser
    #     hashedPassword
    #     extraGroups
    #     ;
    # };
    # home-manager.users.${cfg.name} = {
    #   home = {
    #     inherit (system) stateVersion;
    #   };
    # };
  # };
}
