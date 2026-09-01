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
  paths' ? {
    lib = ./.;
    src = ../../.;
    api = ../../API/nix;
  },
  host ? {},
  schema ? {},
  ...
} @ args: let
  utils = rec {
    inherit
      (builtins)
      attrNames
      concatStringsSep
      elem
      foldl'
      head
      isAttrs
      listToAttrs
      stringLength
      substring
      tail
      ;

    mkCorePaths = name:
      listToAttrs (map (key: {
          name = key;
          value = let
            stems = derived.schema.global.paths.stems.core.${name} or {};
            stem = stems.${key};
            store =
              args.paths.core.${name}.${key}.store
            or (src + ("/" + concatStringsSep "/" stem));
          in {
            inherit store;
            local = toPathStem {
              root = src;
              base = derived.host.paths.src or (toString src);
              self = store;
            };
          };
        }) (
          attrNames (
            removeAttrs
            (derived.schema.global.paths.stems.core.${name} or {})
            ["base"]
          )
        ));

    toPathStem = {
      root ? null,
      src ? null,
      self,
      base ? null,
    }: let
      root' =
        if root != null
        then root
        else src;
      base' =
        if base != null
        then base
        else root';

      str = {
        root = let
          str = toString root';
        in
          if substring (stringLength str - 1) 1 str == "/"
          then str
          else str + "/";

        path = toString self;
      };

      stem = let
        stem =
          if substring 0 (stringLength str.root) str.path == str.root
          then substring (stringLength str.root) (-1) str.path
          else str.path;

        first = substring 0 1 stem;
      in
        if first == "/"
        then substring 1 (stringLength stem - 1) stem
        else stem;
    in
      if stem == ""
      then toString base'
      else toString base' + "/" + stem;

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

      update = {
        inputs = flake.inputs // {nixpkgs = flake.inputs.${core};};
        name = flake.name or name;
        path = flake.path or path;
        home = flake.home or home;
      };
    in
      if core != null
      then flake // update
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
  inherit (utils) normalizeFlake normalizeLib mergeAttrsRecursive toPathStem mkCorePaths;

  derived = {
    flake = normalizeFlake {inherit flake;};
    lib = normalizeLib {inherit lib flake;};

    names = {
      top = names.top or "_";
      lib = names.lib or "lix";
      prefix = names.prefix or ".";
      src = names.src or (flake.name or "dots");
    };

    settings = {
      inherit allowAliases allowTests collisionStrategy;
      exclusions = {
        dirs = excludedDirs;
        files = excludedFiles;
        patterns = excludedPatterns;
      };
    };

    paths = mergeAttrsRecursive (args.paths or {}) {
      core = let
        root = host.paths.src or (toString src);
      in {
        src = {
          store = src;
          local = root;
        };
        lib =
          (mkCorePaths "lib")
          // {
            default = {
              store = self;
              local = toPathStem {
                root = src;
                base = root;
                self = self;
              };
            };
          };
        api = mkCorePaths "api";
        mod = mkCorePaths "mod";
      };
    };

    host =
      if host != {}
      then host
      else derived.schema.hosts.default or {};

    schema =
      if schema != null
      then schema
      else
        internal.schema.construction.mkSchema {
          inherit args;
          api = (internal.filesystem.traversal.importAttrs args.paths.core.api.default.store).value;
          paths = args.paths or {};
        };
  };

  context = let
    self =
      (mergeAttrsRecursive args derived)
      // {seed = extra: import ./internal (mergeAttrsRecursive self extra);};
  in
    self;

  internal = import ./internal context;
in
  internal // {inherit context;}
