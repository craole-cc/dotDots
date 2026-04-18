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
    prj = {
      root = {
        var = "PRJ_ROOT";
        val = paths.src;
      };
      name = {
        var = "PRJ_NAME";
        val = name;
      };
      prefix = {
        var = "PRJ_PREFIX";
        val = toUpper name;
      };
    };

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
        then prj.prefix.var
        else throw "mkEnv: at least one of `prefix` or `name` must be set";
      var =
        if bare
        then key
        else prj.prefix.val + sep + key;
      val = toString path;
    in {inherit var val;};

    mkBinEnv = binName:
      mkEnv {
        path = paths.${binName} or (throw "mkBinEnv: unknown binary '${binName}'");
        prefix = "BIN";
        name = binName;
      };

    mkCfgEnv = cfgName:
      mkEnv {
        path = paths.${cfgName} or (throw "mkCfgEnv: unknown config '${cfgName}'");
        prefix = "CFG";
        name = cfgName;
      };
  in {
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
    mpd = {
      bin = mkBinEnv "mpd";
      cfg = mkCfgEnv "mpd";
    };
    mpv = {
      bin = mkBinEnv "mpv";
      cfg = mkCfgEnv "mpv";
    };
    ytd = {
      bin = mkBinEnv "ytd";
      cfg = mkCfgEnv "ytd";
    };
  };
in {
  inherit description name paths system;
  env = environment;
  lib = libraries;
  pkgs = nixpkgs;
}
