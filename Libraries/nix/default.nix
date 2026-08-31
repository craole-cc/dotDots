{
  collisionStrategy ? "warn",
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  flake ? {},
  lib ? null,
  names ? {},
  allowAliases ? false,
  allowTests ? false,
  src ? ../../.,
  self ? ./.,
  host ? schema.hosts.default or {},
  schema ? {},
  ...
} @ args: let
  utils = rec {
    inherit
      (builtins)
      attrNames
      elem
      foldl'
      head
      isAttrs
      listToAttrs
      stringLength
      substring
      tail
      ;

    toPathStem = {
      root,
      self,
    }: let
      str = {
        root = let
          str = toString root;
        in
          if substring (stringLength str - 1) 1 str == "/"
          then str
          else str + "/";

        path = toString self;
      };
    in
      if substring 0 (stringLength str.root) str.path == str.root
      then substring (stringLength str.root) (-1) str.path
      else str.path;

    unique = list: let
      acc = list: seen:
        if list == []
        then seen
        else let
          x = head list;
          xs = tail list;
        in
          if elem x seen
          then acc xs seen
          else acc xs (seen ++ [x]);
    in
      acc list [];

    mergeAttrsRecursive = let
    in
      set1: set2:
        if isAttrs set1 && isAttrs set2
        then let
          keys = unique (attrNames set1 ++ attrNames set2);
        in
          listToAttrs (
            map (key: {
              name = key;
              value =
                if set1 ? ${key} && set2 ? ${key}
                then mergeAttrsRecursive set1.${key} set2.${key}
                else set2.${key} or set1.${key};
            })
            keys
          )
        else set2;

    isFlakeLike = value:
      isAttrs value
      && value ? inputs
      && isAttrs value.inputs
      && (
        (value ? _type && value._type == "flake")
        || value ? sourceInfo
        || value ? outputs
      );

    isNixpkgsLike = value:
      isAttrs value
      && value ? lib
      && (value ? legacyPackages || value ? packages);

    findFirst = pred: default: list:
      foldl'
      (
        acc: x:
          if acc != default
          then acc #? already found
          else if pred x
          then x #? this one matches
          else default
      )
      default
      list;

    normalizeFlake = {
      flake ? null,
      name ? derived.names.src,
      path ? derived.paths.core.src.store,
      home ? derived.paths.core.src.local,
    }: let
      core =
        if flake != null
        then
          if isFlakeLike flake
          then
            findFirst
            (name: isNixpkgsLike (flake.inputs.${name} or null))
            null
            [
              "nixpkgs"
              "nixPackages"
              "nixPackagesUnstable"
              "nixPackagesStable"
              "nixpkgs-unstable"
              "nixpkgs-stable"
              "unstable"
              "stable"
              "nixos"
              "pkgs"
            ]
          else null
        else null;

      eval = {
        inputs = flake.inputs // {nixpkgs = flake.inputs.${core};};
        # if core != null && core != "nixpkgs"
        # then flake.inputs // {nixpkgs = flake.inputs.${core};}
        # else flake.inputs or {};
        name = flake.name or name;
        path = flake.path or path;
        home = flake.path or home;
      };
    in
      if core != null
      then flake // eval
      else null;

    normalizeLib = {
      lib ? null,
      flake ? {},
      bootstrap ? utils,
      overrides ? {},
      ...
    }: let
      flake' = normalizeFlake {inherit flake;};
    in
      mergeAttrsRecursive
      (mergeAttrsRecursive bootstrap (
        if lib != null && isAttrs lib && lib ? trivial
        then lib
        else if flake' ? inputs.nixpkgs.lib
        then flake'.inputs.nixpkgs.lib
        else import <nixpkgs/lib>
      ))
      (
        if overrides != null
        then overrides
        else {}
      );
  };
  inherit (utils) normalizeFlake normalizeLib mergeAttrsRecursive toPathStem;

  derived = {
    flake = normalizeFlake {inherit flake;};
    lib = normalizeLib {inherit lib flake;};

    names = {
      top = names.top or "_";
      lib = names.lib or "lix";
      prefix = names.prefix or ".";
      src = names.src or (flake.name or "dots");
    };

    config = {
      inherit allowAliases allowTests collisionStrategy;
      exclusions = {
        dirs = excludedDirs;
        files = excludedFiles;
        patterns = excludedPatterns;
      };
    };
    host = host;
    paths.core = let
      root = host.paths.src or (toString src);
    in {
      src = {
        store = src;
        local = root;
      };
      lib.default = {
        store = self;
        local = let
          stem = toPathStem {inherit root self;};
        in
          if stem != "" && stem != toString self
          then root + "/" + stem
          else toString self;
      };
    };
  };

  context = let
    self =
      (mergeAttrsRecursive args derived)
      // {seed = extra: import ./internal (mergeAttrsRecursive self extra);};
  in
    self;
in
  (import ./internal context) // {inherit context;}
