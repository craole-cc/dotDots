{
  config,
  lib,
  ...
}:
let
  inherit (lib) mapAttrs;
  inherit (lib.lists) head;
  inherit (lib.attrsets) attrNames;

  #@ Define reusable path names
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

  #@ Function to calculate paths for a specific host
  mkHostPaths =
    hostName: hostConfig:
    let
      modules = {
        store = hostConfig.paths.store + names.nixos;
        local = hostConfig.paths.local + names.nixos;
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
          shellscript = hostConfig.paths.store + names.scripts.shellscript;
          flake = modules.store + names.scripts.flake;
        };
        local = {
          shellscript = hostConfig.paths.local + names.scripts.shellscript;
          flake = modules.local + names.scripts.flake;
        };
      };

      libraries = {
        store = modules.store + names.libs;
        mkCore = core.libraries + names.mkCore;
        mkConf = core.libraries + names.mkConf;
      };

      parts = modules.store + names.parts;
    in
    {
      inherit
        modules
        devshells
        core
        home
        scripts
        libraries
        parts
        ;
    };

  # Generate paths for all hosts
  hostPaths = mapAttrs mkHostPaths config.hosts;
in
{
  # Set up paths based on hosts
  paths = {
    # Basic common paths
    inherit names;

    # Host-specific paths
    hosts = hostPaths;

    # Current host paths
    current = hostPaths.${config.networking.hostName} or (hostPaths.${head (attrNames hostPaths)});
  };
}
