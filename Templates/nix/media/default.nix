{
  description ? "🎬 Comprehensive Media Environment",
  name ? "media",
  paths ? {
    build = {
      src = ./.;
      modules = rec {
        root = ./modules;
        ytd = root + "/ytd";
        mpv = root + "/mpv";
        mpd = root + "/mpd";
      };
      scripts = ./scripts;
    };

    runtime = rec {
      home = builtins.getEnv "HOME";
      root =
        if home != ""
        then home + "/${name}"
        else ./.;
      cfg = rec {
        base = root + "/.config";
        ytd = base + "/ytd";
        mpv = base + "/mpv";
        mpd = base + "/mpd";
      };
      downloads = root + "/Downloads";
      music = root + "/Music";
      pictures = root + "/Pictures";
      videos = root + "/Videos";
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
  inherit (builtins) head hasAttr isAttrs pathExists tail isPath;
  findFirst = names: set:
    if names == []
    then null
    else let
      name = head names;
    in
      if hasAttr name set
      then name
      else findFirst (tail names) set;

  nixpkgs = let
    name =
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
    if name != null
    then import inputs.${name} cfg
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
  inherit (libraries.strings) toUpper isString typeOf;

  environment = let
    mkEnv = {
      path,
      prefix ? null,
      name ? null,
      flat ? false,
    }: let
      base = "$" + name;
      sep = "_";
      key = toUpper (
        if prefix != null && name != null
        then sep + prefix + sep + name
        else if prefix != null && name == null
        then sep + prefix
        else if prefix == null && name != null
        then sep + name
        else ""
      );
      var =
        if flat
        then key
        else base + key;
      val = toString path;
    in {inherit var val;};

    home = let
      name = "home";
    in {
      env = mkEnv {
        path = paths.runtime.${name};
        flat = true;
      };
    };

    root = let
      name = "root";
    in {
      env = mkEnv {
        path = paths.runtime.${name};
        flat = true;
      };
    };

    build = let
      path = paths.build;
      mkModEnv = arg: let
        base = paths.build.modules;
        fail = msg: throw "mkModEnv: ${msg}";

        requireName = name:
          if !hasAttr name base
          then fail "unknown module '${name}'"
          else name;

        normalizeName = name: let
          name' = requireName name;
        in
          {
            inherit name';
            path = base.${name'};
          }
          // {name = name';};

        normalizeAttr = attrs: let
          name =
            if !(hasAttr "name" attrs)
            then fail "attrset form requires `name`"
            else if !isString attrs.name
            then fail "`name` must be a string"
            else requireName attrs.name;
        in
          if hasAttr "path" attrs
          then
            if !(isString attrs.path || isPath attrs.path)
            then fail "`path` must be a string or path"
            else attrs // {inherit name;}
          else attrs // (removeAttrs (normalizeName name) ["name"]);
      in
        mkEnv (
          if isString arg
          then normalizeName arg
          else if isAttrs arg
          then normalizeAttr arg
          else fail "expected string or attrset, got ${typeOf arg}"
        );
    in {
      ytd = mkModEnv "ytd";
      mpd = mkModEnv "mpd";
      mpv = mkModEnv "mpv";
    };

    music = {
      env = mkEnv {
        ref = music;
        flat = true;
      };
    };
  in {inherit build runtime;};
  # "${prefix}" = toString root;
  # "${prefix}_MOD_YTD" = toString ytd;
  # "${prefix}_MOD_MPD" = toString mpd;
  # "${prefix}_MOD_MPV" = toString mpv;
  # "${prefix}_CFG_BASE" = toString cfg.base;
  # "${prefix}_CFG_YTD" = toString cfg.ytd;
  # "${prefix}_CFG_MPV" = toString cfg.mpv;
  # "${prefix}_CFG_MPD" = toString cfg.mpd;
  # "${prefix}_DOWNLOADS" = toString downloads;
  # "${prefix}_MUSIC" = toString music;
  # "${prefix}_PICTURES" = toString pictures;
  # "${prefix}_VIDEOS" = toString videos;
in {
  inherit description system name;
  lib = libraries;
  paths = {src = ./.;} // paths;
  pkgs = nixpkgs;
  env = environment;
}
