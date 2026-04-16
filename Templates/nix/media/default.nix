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
      bin = rec {
        base = root + "/.bin";
        ytd = base + "/ytd";
        mpv = base + "/mpv";
      };
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
  inherit (builtins) hasAttr head isAttrs pathExists tail;
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
in {
  inherit description system;
  lib = libraries;
  paths = {src = ./.;} // paths;
  pkgs = nixpkgs;
}
