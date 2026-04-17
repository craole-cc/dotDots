{
  description ? "🎬 Comprehensive Media Environment",
  name ? "media",
  paths ? {
    src = ./.;
    bin = rec {
      base = ./.bin;
      ytd = base + "/ytd";
      mpv = base + "/mpv";
      mpd = base + "/mpd";
    };
    cfg = rec {
      base = ./.cfg;
      ytd = base + "/ytd";
      mpv = base + "/mpv";
      mpd = base + "/mpd";
    };
  },
  lib ? null,
  inputs ? null,
  system ?
    if builtins ? currentSystem
    then builtins.currentSystem
    else "x86_64-linux",
  config ? {allowUnfree = true;},
}: let
  inherit (builtins) head hasAttr isAttrs pathExists tail;

  findFirst = names: set:
    if names == []
    then null
    else let
      n = head names;
    in
      if hasAttr n set
      then n
      else findFirst (tail names) set;

  nixpkgs = let
    n =
      if isAttrs inputs
      then
        findFirst [
          "NixPkgsUnstable"
          "NixPackagesUnstable"
          "nixpkgs-unstable"
          "NixPackages"
          "NixPkgs"
          "nixpkgs-stable"
          "nixpkgs"
        ]
        inputs
      else null;
    cfg = {inherit system config;};
  in
    if n != null
    then import inputs.${n} cfg
    else import <nixpkgs> cfg;

  libraries = let
    lib' =
      if isAttrs lib
      then lib
      else nixpkgs.lib;
  in
    if paths ? libraries && pathExists paths.libraries
    then import paths.libraries {lib = lib';}
    else lib';

  inherit (libraries.strings) toUpper;

  environment = let
    projectPrefix = toUpper name;

    mkEnv = {
      path,
      prefix ? null,
      name ? null,
      bare ? false,
    }: let
      sep = "_";
      key =
        if prefix != null && name != null
        then toUpper (prefix + sep + name)
        else if prefix != null
        then toUpper prefix
        else if name != null
        then toUpper name
        else throw "mkEnv: at least one of `prefix` or `name` must be set";
      var =
        if bare
        then key
        else projectPrefix + sep + key;
      val = toString path;
    in {inherit var val;};

    mkCfgEnv = cfgName:
      mkEnv {
        path = paths.${cfgName} or (throw "mkCfgEnv: unknown config '${cfgName}'");
        prefix = "CFG";
        name = cfgName;
      };
  in {
    build = {
      src = mkEnv {
        path = paths.src;
        name = "SRC";
      };
      bin = mkEnv {
        path = paths.bin;
        name = "BIN";
      };
      cfg = mkEnv {
        path = paths.cfg;
        name = "CFG";
      };
      ytd = mkCfgEnv "ytd";
      mpv = mkCfgEnv "mpv";
      mpd = mkCfgEnv "mpd";

      appName = {
        var = "APP_NAME";
        val = name;
      };
      appPrefix = {
        var = "APP_PREFIX";
        val = projectPrefix;
      };
    };
  };
in {
  inherit description name paths system;
  env = environment;
  lib = libraries;
  pkgs = nixpkgs;
}
