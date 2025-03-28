# TODO: Figure out how to make flake.local an option to be set on each system
let
  flake =
    let
      QBX = "/home/craole/.dots";
      Preci = "/home/craole/Projects/dotDots";
      dbook = "/home/craole/Documents/dotfiles";
    in
    {
      store = ./.;
      local = QBX; # TODO: This is to be set based on the current system hostname. Maybe it should be an optional somewhere, but how.
      inherit dbook Preci QBX;
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
      devshells = parts.mods + "/devshells";
    };
  };
  modules = {
    store = flake.store + parts.nixos;
    # QBX = flake.QBX + parts.nixos;
    # dbook = flake.dbook + parts.nixos;
  };
  devshells = {
    default = modules.store + parts.bin.devshells;
    dots = {
      nix = devshells.default + "/dots.nix";
      toml = devshells.default + "/dots.toml";
    };
    media = {
      nix = devshells.default + "/media.nix";
      toml = devshells.default + "/media.toml";
    };
    # local = flake.local + parts.nixos;
    store = flake.store + parts.nixos;
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
    mkCore = core.libraries + parts.mkCore;
    mkConf = core.libraries + parts.mkConf;
  };
in
{
  inherit
    flake
    devshells
    core
    home
    bin
    parts
    modules
    libraries
    ;
}
