{inputs, ...}: let
  alpha = "craole";
  paths = rec {
    flake = let
      QBX = "/home/craole/.dots";
      QBXl = "/home/craole/.dots";
      QBXvm = "/home/craole/.dots";
      Preci = "/home/craole/Projects/dotDots";
      dbook = "/home/craole/Documents/dotfiles";
    in {
      store = ./.;
      local = QBXvm; # TODO: This is to be set based on the current system hostname. Maybe it should be an optional somewhere, but how.
      inherit
        dbook
        Preci
        QBX
        QBXl
        QBXvm
        ;
    };
    parts = {
      args = "/args";
      cfg = "/configurations";
      env = "/environment";
      libs = "/libraries";
      mkCore = "/helpers/mkCoreConfig.nix";
      mkConf = "/helpers/mkConfig.nix";
      shells = "/dev";
      nixos = "/Modules/nixos";
      mods = "/modules";
      opts = "/options";
      pkgs = "/packages";
      shared = "/shared";
      core = "/core";
      defaultUser = "/${alpha}";
      svcs = "/services";
      ui = "/ui";
      uiCore = "/ui/core";
      uiHome = "/ui/home";
      hosts = parts.cfg + "/hosts";
      users = parts.cfg + "/users";
      bin = {
        default = "/Bin";
        cmd = parts.bin.default + "/cmd";
        nix = parts.bin.default + "/nix";
        rust = parts.bin.default + "/rust";
        shellscript = parts.bin.default + "/shellscript";
        scripts = {
          dots = "/Scripts";
          mods = parts.nixos + "/scripts";
        };
        devshells = parts.mods + "/devshell";
      };
    };
    modules = rec {
      store = flake.store + parts.nixos;
      local = flake.local + parts.nixos;
      core = store + "/modules";
      # QBX = flake.QBX + parts.nixos;
      # dbook = flake.dbook + parts.nixos;
    };
    devshells = {
      default = modules.store + parts.bin.devshells;
      dots = devshells.default + "/dots.nix";
      media = devshells.default + "/media.nix";
      # dots = {
      #   nix = devshells.default + "/dots.nix";
      #   toml = devshells.default + "/dots.toml";
      # };
      # media = {
      #   nix = devshells.default + "/media.nix";
      #   toml = devshells.default + "/media.toml";
      # };
      # local = flake.local + parts.nixos;
      store = flake.store + parts.nixos;
    };
    core = {
      base = {
        store = modules.store;
        local = flake.local;
      };
      default = modules.store;
      configurations = {
        hosts = core.default + parts.hosts;
        users = core.default + parts.users;
      };
      environment = core.default + parts.env;
      libraries = core.default + parts.libs;
      modules = core.default + parts.mods;
      options = core.default + parts.opts;
      packages = packages.core;
      shared = {
        packages = packages.core.shared;
      };
      services = core.default + parts.svcs;
      defaultUser = {
        packages = core.packages + "/${alpha}";
      };
    };
    home = {
      default = modules.store + "/home";
      configurations = home.default + parts.cfgs;
      environment = home.default + parts.env;
      libraries = home.default + parts.libs;
      modules = home.default + parts.mods;
      options = home.default + parts.opts;
      packages = home.default + parts.pkgs;
      services = home.default + parts.svcs;
      shared = {
        packages = packages.home.shared;
      };
      defaultUser = {
        packages = packages.home."${alpha}";
      };
    };
    bin = {
      # store = {
      shellscript = flake.store + parts.bin.shellscript;
      flake = modules.store + parts.bin.flake;
      # dots = modules.store + parts.bin + "/init_dots";
      # };
      # QBX = {
      #   shellscript = flake.QBX + parts.bin.shellscript;
      #   flake = modules.QBX + parts.bin.flake;
      #   # dots = flake.QBX + parts.bin.dots;
      # };
    };
    libraries = {
      # local = modules.local + parts.libs;
      store = modules.store + parts.libs;
      global = libraries.store + "/global";
      mkHost = libraries.global + "/mkHost.nix";
      mkCore = core.libraries + parts.mkCore;
      mkConf = core.libraries + parts.mkConf;
    };
    packages = {
      default = modules.store + "/packages";
      custom = packages.default + "/custom";
      overlays = packages.default + "/overlays";
      core = packages.default + "/core";
      home = packages.default + "/home";
      "${alpha}" = rec {
        default = packages.default + "/${alpha}";
        core = default + "/core";
        home = default + "/home";
      };
    };
    hosts = modules.store + "/configurations/hosts";
    users = {
      default = modules.store + "/configurations/users";
      "${alpha}" = rec {
        default = paths.users.default + "/${alpha}";
        home = default + "/home";
        core = default + "/core";
      };
    };
  };
  scripts = with paths.parts.bin; {
    dev = "$DOTS" + shellscript + "/project/nix/devnix";
    eda = "$DOTS" + shellscript + "/packages/alias/edita";
  };
  environment = {
    variables = {
      VISUAL = "eda";
      EDITOR = "eda --helix";
      DOTS_RC = "$DOTS/.dotsrc";
    };
    shellAliases = {
      ".." = "cd .. || exit 1";
      "..." = "cd ../.. || exit 1";
      "...." = "cd ../../.. || exit 1";
      "....." = "cd ../../../.. || exit 1";
      ".dots" = ''cd "$DOTS" || exit 1'';
      devdots = ''${scripts.dev} $DOTS'';
      vsdots = ''${scripts.eda} --dots'';
      hxdots = ''${scripts.eda} --dots --helix'';
      eda = ''${scripts.eda}'';
      dev = ''${scripts.dev}'';

      # ".dots-root" = ''cd ${flake.root}'';
      # ".dots-link" = ''cd ${flake.link}'';
      # Flake = ''if command -v geet ; then geet ; else git add --all; git commit --message "Flake Update" ; fi ; sudo nixos-rebuild switch --flake . --show-trace'';
      # Flash-local = ''geet --path ${flake.local} && sudo nixos-rebuild switch --flake ${flake.local} --show-trace'';
      # Flash-root = ''geet --path ${flake.root} && sudo nixos-rebuild switch --flake ${flake.root} --show-trace'';
      # Flash-link = ''geet --path ${flake.link} && sudo nixos-rebuild switch --flake ${flake.link} --show-trace'';
      # Flash = ''Flash-local'';
      # Flick = ''Flush && Flash && Reboot'';
      # Flick-local = ''Flush && Flash-local && Reboot'';
      # Flick-root = ''Flush && Flash-root && Reboot'';
      # Flick-link = ''Flush && Flash-link && Reboot'';
      Flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
      # Reboot = ''leave --reboot'';
      # Reload = ''leave --logout'';
      # Retire = ''leave --shutdown'';
      Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
      # q = ''leave --terminal'';
      h = "history";
    };
    shellInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
  };
  modules = {
    core = {
      imports = with paths; [
        packages.core
        paths.modules.core
        users.${alpha}.core
      ];
    };
    home = {
      imports = [
        inputs.nixosHome.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bac";
            extraSpecialArgs = {inherit inputs;};
            sharedModules = with paths; [packages.home];
            users.${alpha}.imports = with paths; [
              users.${alpha}.home
            ];
          };
        }
      ];
    };
    wsl = {
      imports = with modules; [
        inputs.nixosWSL.nixosModules.default
        core
        home
        {
          wsl = {
            enable = true;
            defaultUser = alpha;
            startMenuLaunchers = true;
          };
        }
      ];
    };
  };
in {
  inherit
    alpha
    paths
    environment
    modules
    ;
}
