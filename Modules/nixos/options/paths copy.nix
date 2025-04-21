{
  config,
  lib,
  ...
}: {
  options = {
    # Flake Paths
    paths = {
      flake = {
        # Store path (using current directory)
        store = lib.mkOption {
          type = lib.types.path;
          default = ./.;
          description = "Nix store path for the flake";
          readOnly = true;
        };

        # Primary locations
        QBX = lib.mkOption {
          type = lib.types.str;
          default = "/home/craole/.dots";
          description = "Primary dots location";
        };

        Preci = lib.mkOption {
          type = lib.types.str;
          default = "/home/craole/Projects/dotDots";
          description = "Project dotfiles location";
        };

        dbook = lib.mkOption {
          type = lib.types.str;
          default = "/home/craole/Documents/dotfiles";
          description = "Documentation dotfiles location";
        };

        # Local path configuration
        local = lib.mkOption {
          type = lib.types.str;
          default = config.paths.flake.QBX;
          description = "Local path to the current flake repository";
        };
      };

      parts = {
        hosts = lib.mkOption {
          type = lib.types.str;
          default = config.paths.parts.cfgs + "/hosts";
          description = "Path to host configurations";
        };

        users = lib.mkOption {
          type = lib.types.str;
          default = config.paths.parts.cfgs + "/users";
          description = "Path to user configurations";
        };

        scripts = lib.mkOption {
          type = lib.types.attrs;
          default = {
            default = "/Bin";
            cmd = "/Bin/cmd";
            nix = "/Bin/nix";
            rust = "/Bin/rust";
            shellscript = "/Bin/shellscript";
            flake = "/scripts";
            dots = "/Scripts";
            devshells = config.paths.parts.mods + "/devshells";
          };
          description = "Script-related paths";
        };
        args = lib.mkOption {default = "/args";};
        cfgs = lib.mkOption {default = "/configurations";};
        env = lib.mkOption {default = "/environment";};
        libs = lib.mkOption {default = "/libraries";};
        mkCore = lib.mkOption {default = "/helpers/mkCoreConfig.nix";};
        mkConf = lib.mkOption {default = "/helpers/mkConfig.nix";};
        shells = lib.mkOption {default = "/dev";};
        nixos = lib.mkOption {default = "/Modules/nixos";};
        mods = lib.mkOption {default = "/modules";};
        opts = lib.mkOption {default = "/options";};
        pkgs = lib.mkOption {default = "/packages";};
        svcs = lib.mkOption {default = "/services";};
        ui = lib.mkOption {default = "/ui";};
        uiCore = lib.mkOption {default = "/ui/core";};
        uiHome = lib.mkOption {default = "/ui/home";};
      };

      modules = lib.mkOption {
        type = lib.types.attrs;
        default = {
          store = config.paths.flake.store + config.paths.parts.nixos;
        };
        description = "Module paths";
      };

      devshells = lib.mkOption {
        type = lib.types.attrs;
        default = {
          default = config.paths.modules.store + config.paths.parts.scripts.devshells;
          dots = {
            nix = config.paths.devshells.default + "/dots.nix";
            toml = config.paths.devshells.default + "/dots.toml";
          };
          media = {
            nix = config.paths.devshells.default + "/media.nix";
            toml = config.paths.devshells.default + "/media.toml";
          };
        };
        description = "Development shell paths";
      };

      core = lib.mkOption {
        type = lib.types.attrs;
        default = {
          default = config.paths.modules.store;
          configurations = {
            hosts = config.paths.core.default + config.paths.parts.hosts;
            users = config.paths.core.default + config.paths.parts.users;
          };
          environment = config.paths.core.default + config.paths.parts.env;
          libraries = config.paths.core.default + config.paths.parts.libs;
          modules = config.paths.core.default + config.paths.parts.mods;
          options = config.paths.core.default + config.paths.parts.opts;
          packages = config.paths.core.default + config.paths.parts.pkgs;
          services = config.paths.core.default + config.paths.parts.svcs;
        };
        description = "Core configuration paths";
      };

      home = lib.mkOption {
        type = lib.types.attrs;
        default = {
          default = config.paths.modules.store + "/home";
          configurations = config.paths.home.default + config.paths.parts.cfgs;
          environment = config.paths.home.default + config.paths.parts.env;
          libraries = config.paths.home.default + config.paths.parts.libs;
          modules = config.paths.home.default + config.paths.parts.mods;
          options = config.paths.home.default + config.paths.parts.opts;
          packages = config.paths.home.default + config.paths.parts.pkgs;
          services = config.paths.home.default + config.paths.parts.svcs;
        };
        description = "Home configuration paths";
      };

      scripts = lib.mkOption {
        type = lib.types.attrs;
        default = {
          shellscript = config.paths.flake.store + config.paths.parts.scripts.shellscript;
          flake = config.paths.modules.store + config.paths.parts.scripts.flake;
        };
        description = "Script paths";
      };

      libraries = lib.mkOption {
        type = lib.types.attrs;
        default = {
          store = config.paths.modules.store + config.paths.parts.libs;
          mkCore = config.paths.core.libraries + config.paths.parts.mkCore;
          mkConf = config.paths.core.libraries + config.paths.parts.mkConf;
        };
        description = "Library paths";
      };
    };
  };

  # config = {
  #   # Optional: add assertions or additional logic
  #   assertions = [
  #     {
  #       assertion = config.paths.flake.local != "";
  #       message = "paths.flake.local must be set to a valid path";
  #     }
  #   ];
  # };
}
