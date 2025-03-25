{
  perSystem._module.args.paths =
    let
      local = {
        QBX = "$HOME/.dots";
      };
      flake = {
        store = ./.;
      };
      names = {
        args = "/args";
        cfgs = "/configurations";
        env = "/environment";
        libs = "/libraries";
        mkCore = "/helpers/mkCoreConfig.nix";
        mkConf = "/helpers/mkConfig.nix";
        shells = "/dev";
        nixos = "/Modules/nixos";
        mods = "/modules";
        parts = "/components";
        opts = "/options";
        pkgs = "/packages";
        svcs = "/services";
        ui = "/ui";
        uiCore = "/ui/core";
        uiHome = "/ui/home";
        hosts = names.cfgs + "/hosts";
        users = names.cfgs + "/users";
        scripts = {
          default = "/Bin";
          cmd = names.scripts.default + "/cmd";
          nix = names.scripts.default + "/nix";
          rust = names.scripts.default + "/rust";
          shellscript = names.scripts.default + "/shellscript";
          flake = "/scripts";
          dots = "/Scripts";
          devshells = names.mods + "/devshells";
        };
      };
      modules = {
        store = flake.store + names.nixos;
        # QBX = flake.QBX + names.nixos;
        # dbook = flake.dbook + names.nixos;
      };
      devshells = {
        default = modules.store + names.scripts.devshells;
        dots = {
          nix = devshells.default + "/dots.nix";
          toml = devshells.default + "/dots.toml";
        };
        media = {
          nix = devshells.default + "/media.nix";
          toml = devshells.default + "/media.toml";
        };
      };
      core = {
        default = modules.store;
        configurations = {
          hosts = core.default + names.hosts;
          users = core.default + names.users;
        };
        environment = core.default + names.env;
        libraries = core.default + names.libs;
        modules = core.default + names.mods;
        options = core.default + names.opts;
        packages = core.default + names.pkgs;
        services = core.default + names.svcs;
      };
      home = {
        default = modules.store + "/home";
        configurations = home.default + names.cfgs;
        environment = home.default + names.env;
        libraries = home.default + names.libs;
        modules = home.default + names.mods;
        options = home.default + names.opts;
        packages = home.default + names.pkgs;
        services = home.default + names.svcs;
      };
      scripts = {
        store = {
          shellscript = flake.store + names.scripts.shellscript;
          flake = modules.store + names.scripts.flake;
          # dots = modules.store + names.scripts + "/init_dots";
        };
        QBX = {
          shellscript = flake.QBX + names.scripts.shellscript;
          flake = modules.QBX + names.scripts.flake;
          # dots = flake.QBX + names.scripts.dots;
        };
      };
      libraries = {
        # local = modules.local + names.libs;
        store = modules.store + names.libs;
        mkCore = core.libraries + names.mkCore;
        mkConf = core.libraries + names.mkConf;
      };
      parts = modules.store + names.parts;
    in
    {
      inherit
        flake
        modules
        devshells
        core
        home
        scripts
        names
        parts
        libraries
        ;
    };
}
