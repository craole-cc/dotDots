{
  flake,
  modules,
  ...
}:
let
  parts = {
    args = "/args";
    cfgs = "/configurations";
    env = "/environment";
    libs = "/libraries";
    mkCore = "/helpers/mkCoreConfig.nix";
    mkConf = "/helpers/mkConfig.nix";
    shells = "/dev";
    mods = "/modules";
    opts = "/options";
    pkgs = "/packages";
    svcs = "/services";
    ui = "/ui";
    uiCore = "/ui/core";
    uiHome = "/ui/home";
    hosts = parts.cfgs + "/hosts";
    users = parts.cfgs + "/users";
    bin = {
      default = "/Bin";
      cmd = parts.bin.default + "/cmd";
      nix = parts.bin.default + "/nix";
      rust = parts.bin.default + "/rust";
      shellscript = parts.bin.default + "/shellscript";
      flake = "/scripts";
      dots="/Scripts";
      devshells = parts.bin.flake + "/devshells";
    };
  };
  devshells = rec {
    default = modules.store + parts.bin.devshells;
    dots = {
      nix = default + "/dots.nix";
      toml = default + "/dots.toml";
    };
    env = {
      nix = default + "/env.nix";
      toml = default + "/env.toml";
    };
    dev = default + "/dev.toml";
    media = default + "/media.toml";
  };
  core = rec {
    default = modules.store;
    configurations = {
      hosts = default + parts.hosts;
      users = default + parts.users;
    };
    environment = default + parts.env;
    libraries = default + parts.libs;
    modules = default + parts.mods;
    options = default + parts.opts;
    packages = default + parts.pkgs;
    services = default + parts.svcs;
  };
  home = rec {
    default = modules.store + "/home";
    configurations = default + parts.cfgs;
    environment = default + parts.env;
    libraries = default + parts.libs;
    modules = default + parts.mods;
    options = default + parts.opts;
    packages = default + parts.pkgs;
    services = default + parts.svcs;
  };
  scripts = {
    local = {
      shellscript = flake.local + parts.bin.shellscript;
      flake = modules.local + parts.bin.flake;
      dots =  flake.local + parts.bin.dots;
    };
    store = {
      shellscript = flake.store + parts.bin.shellscript;
      flake = modules.store + parts.bin.flake;
      dots = modules.store + parts.scripts + "/init_dots";
    };
  };
  libraries = {
    local = modules.local + parts.libs;
    store = modules.store + parts.libs;
    mkCore = core.libraries + parts.mkCore;
    mkConf = core.libraries + parts.mkConf;
  };
in
{
  inherit
    flake
    modules
    devshells
    core
    home
    scripts
    parts
    libraries
    ;
}
