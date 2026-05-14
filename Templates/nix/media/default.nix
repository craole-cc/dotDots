{
  description ? "🎬 Comprehensive Media Environment",
  name ? "media",
  lib ? null,
  inputs ? null,
  system ? builtins.currentSystem or "x86_64-linux",
  config ? {
    allowUnfree = true;
  },
  sep ? "_",
  paths ? {
    src = {
      store = ./.;
      local = "$PWD";
    };
    bin = {
      base = {
        store = paths.src.store + "/.bin";
        local = paths.src.local + "/.bin";
      };
      mpd = {
        store = paths.bin.base.store + "/mpd";
        local = paths.bin.base.local + "/mpd";
      };
      mpv = {
        store = paths.bin.base.store + "/mpv";
        local = paths.bin.base.local + "/mpv";
      };
      ytd = {
        store = paths.bin.base.store + "/ytd";
        local = paths.bin.base.local + "/ytd";
      };
    };
    cfg = {
      base = {
        store = paths.src.store + "/.cfg";
        local = "$HOME/.config/${name}";
      };
      mpd = {
        store = paths.cfg.base.store + "/mpd";
        local = paths.cfg.base.local + "/mpd";
      };
      mpv = {
        store = paths.cfg.base.store + "/mpv";
        local = paths.cfg.base.local + "/mpv";
      };
      ytd = {
        store = paths.cfg.base.store + "/ytd";
        local = paths.cfg.base.local + "/ytd";
      };
    };
    data = {
      home = {
        inherit (paths.src) store;
        local = "$HOME";
      };
      downloads = {
        store = paths.data.home.store + "/Downloads";
        local = paths.data.home.local + "/Downloads";
      };
      music = {
        store = paths.data.home.store + "/Music";
        local = paths.data.home.local + "/Music";
      };
      pictures = {
        store = paths.data.home.store + "/Pictures";
        local = paths.data.home.local + "/Pictures";
      };
      videos = {
        store = paths.data.home.store + "/Videos";
        local = paths.data.home.local + "/Videos";
      };
    };
  },
}:
let
  inherit (builtins)
    head
    hasAttr
    isAttrs
    pathExists
    tail
    ;

  findFirst =
    names: set:
    if names == [ ] then
      null
    else
      let
        n = head names;
      in
      if hasAttr n set then n else findFirst (tail names) set;

  nixpkgs =
    let
      n =
        if isAttrs inputs then
          findFirst [
            "NixPkgsUnstable"
            "NixPackagesUnstable"
            "nixpkgs-unstable"
            "NixPackages"
            "NixPkgs"
            "nixpkgs-stable"
            "nixpkgs"
          ] inputs
        else
          null;
      cfg = { inherit system config; };
    in
    if n != null then import inputs.${n} cfg else import <nixpkgs> cfg;

  libraries =
    let
      lib' = if isAttrs lib then lib else nixpkgs.lib;
    in
    if paths ? libraries && pathExists paths.libraries then import paths.libraries { lib = lib'; } else lib';
  inherit (libraries.strings) concatStringsSep isString toUpper;
  inherit (libraries.lists) elem;
  inherit (libraries.attrsets) listToAttrs;
  environment =
    let
      toolKinds = [
        "bin"
        "cfg"
      ];
      validKinds = [ "src" ] ++ toolKinds;
      dataKinds = [
        "music"
        "videos"
        "pictures"
        "downloads"
      ];

      mkVar = parts: toUpper (concatStringsSep sep parts);

      #> Flat entry — reads .local from the matching paths leaf
      mkKindEnv = kind: {
        var = mkVar [
          name
          (if kind == "src" then "root" else kind)
        ];
        val = if kind == "src" then paths.src.local else paths.${kind}.base.local;
      };

      #> Nested entry — reads .local for each toolKind from paths
      mkToolEnv =
        tool:
        listToAttrs (
          map (kind: {
            name = kind;
            value = {
              var = mkVar [
                name
                tool
                kind
              ];
              val = paths.${kind}.${tool}.local;
            };
          }) toolKinds
        );

      #> Data dir entry — reads from paths.data
      mkDataEnv = dir: {
        var = mkVar [
          name
          dir
        ];
        val = paths.data.${dir}.local;
      };

      mkEnv =
        args:
        if isString args then
          if elem args validKinds then
            throw "mkEnv: '${args}' is a kind — use { key = \"${args}\"; flat = true; }"
          else if elem args dataKinds then
            mkDataEnv args
          else
            mkToolEnv args
        else if args.flat or false then
          if !(elem args.key validKinds) then
            throw "mkEnv: invalid kind '${args.key}', must be one of ${toString validKinds}"
          else
            mkKindEnv args.key
        else
          throw "mkEnv: expected a string or { key; flat = true; }";
    in
    {
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
    }
    // listToAttrs (
      map (dir: {
        name = dir;
        value = mkEnv dir;
      }) dataKinds
    );
in
{
  inherit
    description
    name
    paths
    system
    environment
    libraries
    ;
  env = environment;
  lib = libraries;
  pkgs = nixpkgs;
}
