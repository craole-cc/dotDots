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
  names ? {
    src = "dots";
    top = "_";
    lib = "lix";
  },
  paths ? {
    src = ../../.;
    lib = ./.;
  },
  target ? null,
  host ? target,
  allowAliases ? false,
  allowTests ? false,
  stems ? {},
  ...
} @ args: let
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
    typeOf
    ;

  getEnvOr = key: fallback: let
    value = builtins.getEnv key;
  in
    if value == ""
    then fallback
    else value;

  attrNamesHead = set: let
    err = {
      isNull = "attrNamesHead: set is null";
      notAttrs = "attrNamesHead: argument is not an attribute set (got ${typeOf set})";
      isEmpty = "attrNamesHead: set is empty";
    };
    attrs = attrNames set;
  in
    if set == null
    then throw err.isNull
    else if !isAttrs set
    then throw err.notAttrs
    else if attrs == []
    then throw err.isEmpty
    else head attrs;

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

  toUpper =
    if lib ? strings.toUpper
    then lib.strings.toUpper
    else
      value:
        replaceStrings
        ["a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z"]
        ["A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]
        value;

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
            else set2.${key} or set1.${key};
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
    isKwargs =
      isAttrs arg
      && (arg ? condition || arg ? name || arg ? value);
    condition =
      if isKwargs
      then arg.condition or true
      else true;
    name =
      if isKwargs
      then arg.name or null
      else null;
    value =
      if isKwargs
      then arg.value or arg
      else arg;
  in
    if
      condition
      && (isAttrs value && value != {})
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
    root, # single local value
    stem,
    vars ? [],
    envPrefix ? null,
    envSegments ? [],
  }: let
    isVar = value:
      isAttrs value && value ? var && isString value.var;

    normalizeSegment = segment: let
      err = {
        unknownVar = ''
          mkPath: unknown variable "${segment.var}".
          Allowed variables: ${toJSON vars}
        '';
        unsupported = "mkPath: unsupported path segment: ${toJSON segment}";
      };
    in
      if isString segment || isPath segment
      then toString segment
      else if isVar segment
      then
        if elem segment.var vars
        then getEnvOr segment.var "\${${segment.var}}"
        else throw err.unknownVar
      else throw err.unsupported;

    normalize = part:
      if isList part
      then concatStringsSep "/" (map normalizeSegment part)
      else normalizeSegment part;

    root' = normalize root;
    stem' = normalize stem;

    absolute = stem' != "" && substring 0 1 stem' == "/";

    join = base:
      if absolute
      then stem'
      else if base == ""
      then stem'
      else if stem' == ""
      then base
      else if base == "/"
      then "/${stem'}"
      else "${base}/${stem'}";

    paths = {
      local = join root';
      store = join root';
    };

    env = concatStringsSep "_" (
      (
        if envPrefix == null
        then []
        else [
          (toUpper (replaceStrings ["-"] ["_"] envPrefix))
        ]
      )
      ++ map (s: toUpper (replaceStrings ["-"] ["_"] s))
      (filter (s: s != "default") envSegments)
    );
  in
    {inherit stem env;} // paths;

  mkTree = {
    vars ? [],
    stems,
    roots,
    paths ? {},
  }: let
    err = {
      missingRoot = key: "mkTree: missing root for domain '${key}'";
    };

    isVar = value:
      isAttrs value && value ? var && isString value.var;

    mk = {
      domain,
      domainName,
      stem,
      overrides,
      envSegments ? [],
    }:
      if isAttrs stem && !isVar stem
      then
        mapAttrs (
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
            then null
            else defined.names.src or derived.names.src;
          inherit envSegments;
        };
        merged = mergeAttrs generated (asAttrs overrides);
      in
        merged // {inherit (generated) env;};

    tree = {
      inherit stems;

      roots =
        mapAttrs (
          key: _:
            if roots ? ${key}
            then roots.${key}
            else throw (err.missingRoot key)
        )
        stems;

      build =
        mapAttrs (
          key: stem:
            mk {
              inherit stem;
              domain = tree.roots.${key};
              domainName = key;
              overrides = paths.${key} or {};
            }
        )
        stems;

      paths = tree.build;

      variables = let
        collect = node:
          if isAttrs node && node ? env && node ? local
          then {${node.env} = node.local;}
          else if isAttrs node
          then foldl' (acc: key: acc // collect node.${key}) {} (attrNames node)
          else {};
        src = defined.names.src or derived.names.src;
      in
        collect tree.build
        // (
          if tree.build ? core.src.local
          then {${toUpper src} = tree.build.core.src.local;}
          else {}
        );
    };
  in
    {inherit (tree) roots stems variables;} // tree.paths;

  derived = mergeAttrs args {
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

    paths = let
      src = args.paths.src or (paths.src or ../../.);
      self = args.paths.lib or (paths.lib or ../../.);
    in
      mkTree {
        roots.core =
          if flake != null && flake ? home && flake.home != null
          then flake.home
          else getEnvOr "PWD" (toString src);

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

    api = let
      base = import derived.paths.core.api.store;
      inherit (base) hosts users;

      host' = let
        default = getEnvOr "HOSTNAME" (attrNamesHead hosts);

        err = {
          unknown = name: "Unknown host targeted: ${name}";
          missingKeys = "Target host attribute set missing required keys (`paths.src`, `stateVersion`)";
          invalidType = "The target host must be an attribute set, host name, or null (got ${typeOf host})";
        };

        lookup = name: hosts.${name} or (throw (err.unknown name));
      in
        if host == null
        then lookup default
        else if isString host
        then lookup host
        else if isAttrs host
        then
          if host ? paths.src && host ? stateVersion
          then host
          else throw err.missingKeys
        else throw err.invalidType;

      user' = let
        err = {
          unknown = name: "Unknown user targeted: ${name}";
          undefined = "Unable to determine host user from configuration";
        };

        name = getEnvOr "USER" (
          host'.users.primary.name or (
            if (host'.principals or []) != []
            then (head host'.principals).name
            else throw err.undefined
          )
        );
      in
        users.${name} or (throw (err.unknown name));
    in
      base
      // {
        hosts = hosts // {default = host';};
        users = users // {default = user';};
      };
  };

  defined = let
    inherit (derived.api) global hosts;
  in {
    paths = mkTree {
      inherit (global) vars;
      stems = let
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

        base = global.paths.stems;
        core = let
          extra = {
            src = derived.paths.stems.core.src;
            api =
              base.core.api
              // {default = assertMatch "api" base.core.api.default;};
            lib =
              base.core.lib
              // {default = assertMatch "lib" base.core.lib.default;};
          };
        in
          base.core // extra;
      in
        mergeAttrs (base // {inherit core;}) stems;

      roots = let
        base = global.paths.roots;
        core =
          if host != null && isString host && hosts ? ${host} && hosts.${host} ? paths.src
          then hosts.${host}.paths.src
          else if host != null && isAttrs host && host ? paths.src
          then host.paths.src
          else derived.paths.roots.core;
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
    base
    // meta
    // {
      flake = base.flake // meta;
      inherit target host mkPath mkTree;
    };

  assemble = import ./internal resolved;
in
  assemble
