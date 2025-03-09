{
  store,
  local,
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
    default = store + parts.devShells;
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
  core = {
    default = modules.store;
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
    default = modules.store + "/home";
    configurations = home.default + parts.cfgs;
    environment = home.default + parts.env;
    libraries = home.default + parts.libs;
    modules = home.default + parts.mods;
    options = home.default + parts.opts;
    packages = home.default + parts.pkgs;
    services = home.default + parts.svcs;
  };
  scripts = {
    global = local + parts.bin;
    local = modules.store + parts.scripts;
    store = store + parts.scripts;
    dots = modules.store + parts.scripts + "/init_dots";
  };
  # modules = {
  #   local = flake.local + parts.modules;
  #   store = flake.store + parts.modules;
  # };
  libraries = {
    local = modules.local + parts.libs;
    store = modules.store + parts.libs;
    mkCore = core.libraries + parts.mkCore;
    mkConf = core.libraries + parts.mkConf;
  };
in
{
  inherit
    devShells
    core
    home
    scripts
    parts
    libraries
    ;
}
