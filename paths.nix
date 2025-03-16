let
  flake = {
    store = ./.;
    QBX = /home/craole/.dots;
    dbook = /home/craole/Documents/dotfiles;
  };
  parts = {
    args = "/args";
    cfgs = "/configurations";
    env = "/environment";
    libs = "/libraries";
    mkCore = "/helpers/mkCoreConfig.nix";
    mkConf = "/helpers/mkConfig.nix";
    shells = "/dev";
    nixos = "/Modules/nixos";
    mods = "/modules";
    opts = "/options";
    pkgs = "/packages";
    svcs = "/services";
    ui = "/ui";
    uiCore = "/ui/core";
    uiHome = "/ui/home";
    hosts = parts.cfgs + "/hosts";
    users = parts.cfgs + "/users";
    scripts = {
      default = "/Bin";
      cmd = parts.scripts.default + "/cmd";
      nix = parts.scripts.default + "/nix";
      rust = parts.scripts.default + "/rust";
      shellscript = parts.scripts.default + "/shellscript";
      flake = "/scripts";
      dots = "/Scripts";
      devshells = parts.mods + "/devshells";
    };
  };
  modules = {
    store = flake.store + parts.nixos;
    QBX = flake.QBX + parts.nixos;
    dbook = flake.dbook + parts.nixos;
  };
  devshells = {
    default = modules.store + parts.scripts.devshells;
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
    store = {
      shellscript = flake.store + parts.scripts.shellscript;
      flake = modules.store + parts.scripts.flake;
      # dots = modules.store + parts.scripts + "/init_dots";
    };
    QBX = {
      shellscript = flake.QBX + parts.scripts.shellscript;
      flake = modules.QBX + parts.scripts.flake;
      # dots = flake.QBX + parts.scripts.dots;
    };
  };
  # libraries = {
  #   # local = modules.local + parts.libs;
  #   store = modules.store + parts.libs;
  #   mkCore = core.libraries + parts.mkCore;
  #   mkConf = core.libraries + parts.mkConf;
  # };
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
    # libraries
    ;
}
