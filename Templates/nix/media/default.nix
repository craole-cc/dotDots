{
  description ? "🎬 Comprehensive Media Environment",
  name ? "media",
  paths ? {
    build = {
      src = ./.;
      cfg = rec {
        root = ./config;
        ytd = root + "/ytd";
        mpv = root + "/mpv";
        mpd = root + "/mpd";
      };
      bin = ./scripts;
    };

    runtime = let
      relPaths = {
        cfg = {
          base = ".config";
          ytd = ".config/ytd";
          mpv = ".config/mpv";
          mpd = ".config/mpd";
        };
        downloads = "Downloads";
        music = "Music";
        pictures = "Pictures";
        videos = "Videos";
      };
      home = builtins.getEnv "HOME";
      root =
        (
          if home != ""
          then home
          else toString ./.
        )
        + "/${name}";
      abs = rel: root + "/" + rel;
    in rec {
      inherit relPaths root;
      cfg = {
        base = abs relPaths.cfg.base;
        ytd = abs relPaths.cfg.ytd;
        mpv = abs relPaths.cfg.mpv;
        mpd = abs relPaths.cfg.mpd;
      };
      downloads = abs relPaths.downloads;
      music = abs relPaths.music;
      pictures = abs relPaths.pictures;
      videos = abs relPaths.videos;
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
  inherit (libraries.strings) concatStringsSep toUpper;

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
      #? bare = true  → bare system var e.g. HOME, XDG_CONFIG_HOME
      #? bare = false → project-namespaced var e.g. MEDIA_BIN_YTD
      var =
        if bare
        then key
        else projectPrefix + sep + key;
      val = toString path;
    in {inherit var val;};

    mkBinEnv = binName: let
      base = paths.build.cfg;
      path = base.${binName} or (throw "mkBinEnv: unknown binule '${binName}'");
    in
      mkEnv {
        inherit path;
        prefix = "BIN";
        name = binName; # → MEDIA_BIN_YTD, MEDIA_BIN_MPD, MEDIA_BIN_MPV
      };

    # Generates a self-contained bash function that exports all runtime vars
    # relative to a base path passed as $1 (defaults to $HOME/<name>).
    # Uses paths.runtime.relPaths so the structure stays in sync with the
    # paths definition above — no duplication.
    mkRuntimeSetup = let
      r = paths.runtime.relPaths;
      p = projectPrefix;
      exports = [
        {
          var = "${p}_ROOT";
          rel = null;
        }
        {
          var = "${p}_NAME"; # "media"
          rel = null;
        }
        {
          var = "${p}_PREFIX"; # "MEDIA"
          rel = null;
        }
        {
          var = "${p}_CFG_BASE";
          rel = r.cfg.base;
        }
        {
          var = "${p}_CFG_YTD";
          rel = r.cfg.ytd;
        }
        {
          var = "${p}_CFG_MPV";
          rel = r.cfg.mpv;
        }
        {
          var = "${p}_CFG_MPD";
          rel = r.cfg.mpd;
        }
        {
          var = "${p}_DOWNLOADS";
          rel = r.downloads;
        }
        {
          var = "${p}_MUSIC";
          rel = r.music;
        }
        {
          var = "${p}_PICTURES";
          rel = r.pictures;
        }
        {
          var = "${p}_VIDEOS";
          rel = r.videos;
        }
      ];
      mkLine = {
        var,
        rel,
      }:
        if rel == null
        then "  export ${var}=\"$_root\""
        else "  export ${var}=\"$_root/${rel}\"";
      lines = concatStringsSep "\n" (map mkLine exports);
    in ''
      setup_${name}_runtime() {
        local _root="''${1:-''${HOME}/${name}}"
      ${lines}
      }
    '';
  in {
    build = {
      ytd = mkBinEnv "ytd";
      mpd = mkBinEnv "mpd";
      mpv = mkBinEnv "mpv";
      bin = mkEnv {
        path = paths.build.bin;
        name = "BIN"; # → MEDIA_BIN
      };
    };
    inherit mkRuntimeSetup;
  };
in {
  inherit description system name;
  lib = libraries;
  paths = {src = ./.;} // paths;
  pkgs = nixpkgs;
  env = environment;
}
