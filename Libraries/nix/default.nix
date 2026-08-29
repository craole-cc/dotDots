{
  collisionStrategy ? "warn",
  excludedDirs ? [
    "review"
    "archive"
    "internal"
    "imports"
    "data"
    "test"
    "tmp"
    "temp"
    "wip"
    "deprecated"
    "experimental"
    "backup"
  ],
  excludedFiles ? [
    "default.nix"
    "flake.nix"
  ],
  excludedPatterns ? [
    " copy.nix"
    ".test.nix"
    ".spec.nix"
    ".bak.nix"
    ".old.nix"
  ],
  flake ? {},
  lib ? null,
  names ? null,
  stems ? {},
  target ? null,
  host ? target,
  allowAliases ? false,
  allowTests ? false,
  src ? ../../.,
  self ? ./.,
  ...
}: let
  inherit
    (builtins)
    attrNames
    concatStringsSep
    elem
    filter
    foldl'
    head
    isAttrs
    isList
    isPath
    isString
    listToAttrs
    mapAttrs
    replaceStrings
    split
    stringLength
    substring
    tail
    toJSON
    ;

  getEnvOr = key: fallback: let
    value = builtins.getEnv key;
  in
    if value == "" then fallback else value;

  /**
  Deduplicates items in a list without external lib dependencies
  */
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

  namesSrc =
    if names != null && names ? src && names.src != null
    then names.src
    else if flake == null
    then "dots"
    else flake.name or "dots";

  localHome =
    if flake != null && flake ? home && flake.home != null
    then flake.home
    else getEnvOr "PWD" (toString src);

  toUpper =
    if lib == null
    then
      value:
        replaceStrings
        [ "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ]
        [ "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ]
        value
    else lib.strings.toUpper;

  /**
  Recursive deep merge without allocating temporary sets for key scanning
  */
  mergeAttrs = set1: set2:
    if isAttrs set1 && isAttrs set2
    then let
      keys = unique (attrNames set1 ++ attrNames set2);
    in
      listToAttrs (
        map (key: {
          name = key;
          value =
            if set1 ? ${key} && set2 ? ${key}
            then mergeAttrs set1.${key} set2.${key}
            else if set2 ? ${key}
            then set2.${key}
            else set1.${key};
        })
        keys
      )
    else set2;

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

  asAttrs = arg: let
    #? Heuristic to determine if the argument is our kwargs structure
    #? If the attrset contains any of our reserved keys, treat it as kwargs
    isKwargs = isAttrs arg && (arg ? condition || arg ? name || arg ? value);

    #> Extract properties with fallbacks
    condition =
      if isKwargs && arg ? condition
      then arg.condition
      else true; # Default to true if omitted
    name =
      if isKwargs && arg ? name
      then arg.name
      else null;
    value =
      if isKwargs && arg ? value
      then arg.value
      else arg;
  in
    if
      condition
      && (value != null && isAttrs value && value != {})
    then
      if name != null
      then {"${name}" = value;}
      else value
    else {};

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

  mkPath = {
    root,
    stem,
    vars ? [],
    envPrefix ? null,
    envSegments ? [],
  }: let
    isVar = value:
      isAttrs value
      && value ? var
      && isString value.var;

    normalize = part: let
      normalizeSegment = segment:
        if isString segment || isPath segment
        then toString segment
        else if isVar segment
        then
          if elem segment.var vars
          then "\${${segment.var}}"
          else
            throw ''
              mkPath: unknown variable "${segment.var}".
              Allowed variables: ${toJSON vars}
            ''
        else throw "mkPath: unsupported path segment: ${toJSON segment}";
    in
      if isList part
      then concatStringsSep "/" (map normalizeSegment part)
      else normalizeSegment part;

    storeRoot =
      if isAttrs root && root ? store
      then root.store
      else null;
    localRoot =
      if isAttrs root && root ? local
      then root.local
      else if storeRoot == null
      then root
      else null;

    root' = if localRoot == null then null else normalize localRoot;
    stem' = normalize stem;

    absolute =
      (stem' != "")
      && substring 0 1 stem' == "/";
    join = root:
      if root == null
      then null
      else if absolute
      then stem'
      else if root == ""
      then stem'
      else if stem' == ""
      then root
      else if root == "/"
      then "/${stem'}"
      else "${root}/${stem'}";

    store = join (if storeRoot == null then null else normalize storeRoot);
    local = join (if localRoot == null then null else root');
    envRoot =
      if isVar localRoot
      then localRoot
      else null;
    envName =
      concatStringsSep "_"
      (
        [
          (toUpper (replaceStrings ["-"] ["_"] (if envPrefix == null then "PATH" else envPrefix)))
        ]
        ++ map (segment: toUpper (replaceStrings ["-"] ["_"] segment))
          (filter (segment: segment != "default") envSegments)
      );
  in {
    inherit stem store local;
    env = envName;
  };

  mkTree = {
    vars ? [],
    stems,
    roots,
    paths ? {},
  }: let
    isVar = value:
      isAttrs value
      && value ? var
      && isString value.var;

    normalizeRoot = root:
      if
        isAttrs root
        && !isVar root
        && (root ? store || root ? local)
      then root
      else {
        local = root;
      };

    mk = {
      domain,
      domainName,
      stem,
      overrides,
      envSegments ? [],
    }:
      if isAttrs stem && !isVar stem
      then
        mapAttrs
        (
          key: stem:
            mk {
              inherit domain domainName stem;
              overrides = overrides.${key} or {};
              envSegments = envSegments ++ [key];
            }
        )
        stem
      else let
        generated = mkPath {
          root = domain;
          inherit stem vars;
          envPrefix =
            if domainName == "base"
            then domainName
            else namesSrc;
          inherit envSegments;
        };
        merged = mergeAttrs generated (asAttrs overrides);
      in
        merged // {env = generated.env;};

    inputPaths = paths;
    inputRoots = roots;

    resolvedRoots =
      mapAttrs
      (
        key: _:
          if inputRoots ? ${key}
          then normalizeRoot inputRoots.${key}
          else throw "mkTree: missing root for domain '${key}'"
      )
      stems;

    built =
      mapAttrs
      (
        key: stem:
          mk {
            inherit stem;
            domain = resolvedRoots.${key};
            domainName = key;
            overrides = inputPaths.${key} or {};
          }
      )
      stems;

    flattenStore = node:
      if isAttrs node && node ? store
      then node.store
      else mapAttrs (_: flattenStore) node;
    collectVariables = node:
      if isAttrs node && node ? env && node ? local
      then {${node.env} = node.local;}
      else if isAttrs node
      then foldl' (acc: key: acc // collectVariables node.${key}) {} (attrNames node)
      else {};
    resolvedPaths = built // (flattenStore built.core);
  in
    {
      roots = resolvedRoots;
      variables = collectVariables built;
      inherit stems;
    }
    // resolvedPaths;

  derived = {
    config = {
      inherit allowAliases allowTests collisionStrategy;
      exclusions = {
        dirs = excludedDirs;
        files = excludedFiles;
        patterns = excludedPatterns;
      };
    };

    names = {
      top = names.top or "dots";
      lib = names.lib or "lix";
      prefix = names.prefix or ".";
      src = names.src or (flake.name or "dots");
    };

    paths = mkTree {
      roots.core = {
        store = src;
        local = localHome;
      };

      stems.core = {
        src = [];

        lib = let
          str = {
            src = toString src;
            lib = toString self;
          };

          relative =
            if str.src == str.lib
            then ""
            else
              substring
              (stringLength str.src + 1)
              (stringLength str.lib - stringLength str.src - 1)
              str.lib;
        in
          if relative == ""
          then []
          else filter isString (split "/" relative);

        api = ["API" "nix"];
      };
    };

    flake = let
      core =
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
        else null;
    in
      flake
      // {
        inputs =
          if core != null && core != "nixpkgs"
          then flake.inputs // {nixpkgs = flake.inputs.${core};}
          else flake.inputs or {};
      };

    lib =
      if lib != null && isAttrs lib
      then lib
      else if
        derived ? flake
        && derived.flake ? inputs
        && derived.flake.inputs ? nixpkgs
      then derived.flake.inputs.nixpkgs.lib
      else import <nixpkgs/lib>;
  };

  defined = {
    api = import derived.paths.core.api.store;
    paths = mkTree {
      vars = defined.api.global.vars;

      stems = let
        base = defined.api.global.paths.stems;

        assertMatch = name: value: let
          bootstrap = derived.paths.stems.core.${name};
        in
          if bootstrap == value
          then value
          else
            throw ''
              ${derived.names.src}: stem mismatch for "core.${name}"

              bootstrap computed:
                ${toJSON bootstrap}

              api.global.paths reports:
                ${toJSON value}

              Reconcile derived.paths.stems.core.${name}
              against api.global.paths.stems.core.${name}.
            '';

        core =
          base.core
          // {
            src = derived.paths.stems.core.src;
            api = base.core.api // {default = assertMatch "api" base.core.api.default;};
            lib = base.core.lib // {default = assertMatch "lib" base.core.lib.default;};
          };
      in
        mergeAttrs (base // {inherit core;}) stems;

      roots = let
        base = defined.api.global.paths.roots;
        core = {
          store = src;
          local = localHome;
        };
      in
        base // {inherit core;};
    };
  };

  resolved = let
    base = derived // defined;
    meta = let
      name = base.flake.name or base.names.src;
      path = base.flake.path or base.paths.core.src.store;
      home = let
        path' =
          base.flake.home or (
            base.paths.core.src.local or null
          );
      in
        if path' != null && path' != ""
        then path'
        else path;
    in {inherit name path home;};
  in
    base // meta // {flake = base.flake // meta; inherit target host mkPath mkTree;};

  assemble = import ./internal resolved;
in
  assemble
