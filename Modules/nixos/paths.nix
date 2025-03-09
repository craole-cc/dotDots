{ flake, ... }:
let
  parts = {
    args = "/args";
    cfgs = "/configurations";
    env = "/environment";
    libs = "/libraries";
    mkCore = "/helpers/mkCoreConfig.nix";
    mkConf = "/helpers/mkConfig.nix";
    modules = "/Modules/nixos";
    devShells = "/Modules/dev";
    mods = "/modules";
    opts = "/options";
    pkgs = "/packages";
    bin = "/Bin";
    svcs = "/services";
    ui = "/ui";
    uiCore = "/ui/core";
    uiHome = "/ui/home";
    hosts = parts.cfgs + "/hosts";
    users = parts.cfgs + "/users";
    scripts = "/scripts";
  };
  devShells = rec {
    default = flake.store + parts.devShells;
    dots = default + "/dots.nix";
    dotsToml = default + "/dots.toml";
    dev = default + "/dev.toml";
    env = default + "/env.toml";
    media = default + "/media.toml";
  };
  core = {
    default = flake.modules.store;
    configurations = {
      hosts = core.default + parts.hosts;
      users = core.default + parts.users;
    };
    environment = core.default + parts.env;
    libraries = core.default + parts.libs;
    modules = core.default + parts.mods;
    options = core.default + parts.opts;
    packages = core.default + parts.pkgs;
    services = core.default + parts.svcs;
  };
  home = {
    default = flake.modules.store + "/home";
    configurations = home.default + parts.cfgs;
    environment = home.default + parts.env;
    libraries = home.default + parts.libs;
    modules = home.default + parts.mods;
    options = home.default + parts.opts;
    packages = home.default + parts.pkgs;
    services = home.default + parts.svcs;
  };
  scripts = {
    global = flake.local + parts.bin;
    local = flake.modules.store + parts.scripts;
    store = flake.store + parts.scripts;
    dots = flake.modules.store + parts.scripts + "/init_dots";
  };
  # modules = {
  #   local = flake.local + parts.modules;
  #   store = flake.store + parts.modules;
  # };
  libraries = {
    local = flake.modules.local + parts.libs;
    store = flake.modules.store + parts.libs;
    mkCore = core.libraries + parts.mkCore;
    mkConf = core.libraries + parts.mkConf;
  };
in
{
  inherit
    flake
    devShells
    core
    home
    scripts
    parts
    libraries
    ;
}
