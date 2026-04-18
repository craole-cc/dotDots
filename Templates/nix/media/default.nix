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

  inherit (libraries.strings) concatStringsSep isString toUpper;
  inherit (libraries.lists) elem;
  inherit (libraries.attrsets) listToAttrs;

  environment = let
    toolKinds = ["bin" "cfg"];
    validKinds = ["src"] ++ toolKinds;

    mkVar = {
      parts,
      sep ? "_",
    }:
      toUpper (concatStringsSep sep parts);

    mkKindEnv = kind: {
      var = mkVar {
        parts = [
          name
          (
            if kind == "src"
            then "root"
            else kind
          )
        ];
      };
      val =
        if kind == "src"
        then paths.src
        else paths.${kind}.base;
    };

    mkToolEnv = tool:
      listToAttrs (map (kind: {
          name = kind;
          value = {
            var = mkVar {parts = [name tool kind];};
            val = paths.${kind}.${tool};
          };
        })
        toolKinds);

    mkEnv = args:
      if isString args
      then
        if elem args validKinds
        then throw "mkEnv: '${args}' is a kind, did you mean to use { key = \"${args}\"; flat = true; }?"
        else mkToolEnv args
      else if args.flat or false
      then
        if !(elem args.key validKinds)
        then throw "mkEnv: invalid kind '${args.key}', must be one of ${toString validKinds}"
        else mkKindEnv args.key
      else throw "mkEnv: expected a string tool name or { key; flat = true; }";
  in {
    src = mkEnv {
      key = "src";
      flat = true;
    };
    bin = mkEnv {
      key = "bin";
      flat = true;
    };
    cfg = mkEnv {
      key = "cfg";
      flat = true;
    };
    mpd = mkEnv "mpd";
    mpv = mkEnv "mpv";
    ytd = mkEnv "ytd";
  };
in {
  inherit description name paths system;
  env = environment;
  lib = libraries;
  pkgs = nixpkgs;
}
