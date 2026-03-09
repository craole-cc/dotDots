{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.filesystem.paths) flakePath;
  inherit (_.hardware.systems) getSystems;
  inherit (_.values.empty) isNotEmpty;
  inherit
    (lib.attrsets)
    attrByPath
    attrValues
    filterAttrs
    genAttrs
    hasAttrByPath
    optionalAttrs
    ;
  inherit (lib.debug) traceIf;
  inherit (lib.lists) filter findFirst head toList;
  inherit (builtins) getFlake;

  /**
  Get an attribute value, falling back to `default` if missing or empty.

  Unlike `attrs.key or default`, `get` correctly handles empty strings,
  empty lists, and empty attrsets, treating all of them as absent.

  # Type
  ```nix
  get :: AttrSet -> string -> a -> a
  ```

  # Examples
  ```nix
  get { a = "hello"; } "a" "fallback"  # => "hello"
  get { a = "";      } "a" "fallback"  # => "fallback"  (empty string)
  get {}               "a" "fallback"  # => "fallback"  (missing)
  get { a = 0;       } "a" 42          # => 0           (zero is not empty)
  get { a = false;   } "a" true        # => false        (false is not empty)
  get { a = [];      } "a" [1 2]       # => [1 2]       (empty list)
  ```
  */
  get = attrs: name: default:
    if attrs ? ${name} && isNotEmpty attrs.${name}
    then attrs.${name}
    else default;

  /**
  Get an attribute value, falling back to `default` only if the key is absent.

  Unlike `get`, preserves empty strings, empty lists, and empty attrsets.

  # Type
  ```nix
  orNull :: AttrSet -> string -> a -> a
  ```

  # Examples
  ```nix
  orNull { a = ""; } "a" "fallback"   # => ""        (exists, even if empty)
  orNull { a = []; } "a" [1]          # => []        (exists, even if empty)
  orNull {}          "a" "fallback"   # => "fallback" (missing)
  orNull { a = null; } "a" "fallback" # => null       (exists)
  ```
  */
  orNull = attrs: name: default:
    if attrs ? ${name}
    then attrs.${name}
    else default;

  /**
  Resolve an attribute by trying multiple paths in order.

  Returns the value at the first matching path, or `default` if none exist.

  # Type
  ```nix
  byPaths :: { attrset :: AttrSet, paths :: [[string]], default :: a } -> a
  ```

  # Examples
  ```nix
  byPaths {
    attrset = { foo.bar = 1; baz.qux = 2; };
    paths   = [["missing"] ["foo" "bar"] ["baz" "qux"]];
    default = null;
  }
  # => 1  (first match: foo.bar)

  # Package variant selection
  byPaths {
    attrset = pkgs;
    paths   = [["firefox-beta"] ["firefox-esr"] ["firefox"]];
  }
  # => pkgs.firefox-beta if it exists, else firefox-esr, else firefox
  ```
  */
  byPaths = {
    attrset,
    paths,
    default ? {},
  }: let
    matched = filter (path: hasAttrByPath path attrset) paths;
  in
    if isNotEmpty matched
    then attrByPath (head matched) default attrset
    else default;

  /**
  Resolve a nested attribute under any of several possible parent names.

  Useful for flake inputs where the input name may vary but the nested
  structure is consistent.

  # Type
  ```nix
  nestedByPaths :: { attrset :: AttrSet, parents :: string | [string], target :: string | [string], default :: a } -> a
  ```

  # Examples
  ```nix
  nestedByPaths {
    attrset = inputs;
    parents = ["zenBrowser" "zen-browser" "zen"];
    target  = "homeModules";
  }
  # => inputs.zenBrowser.homeModules (if exists), falling back down the list
  ```
  */
  nestedByPaths = {
    attrset,
    parents,
    target,
    default ? {},
  }:
    byPaths {
      inherit attrset default;
      paths = map (parent: [parent] ++ toList target) (toList parents);
    };

  /**
  Get `legacyPackages` from a nixpkgs flake for a given system.

  # Type
  ```nix
  packages :: { nixpkgs :: Flake?, system :: string?, priority :: [string]? } -> AttrSet
  ```
  */
  packages = {
    nixpkgs ? import <nixpkgs> {},
    system ? null,
    priority ? null,
  }: let
    targetSystem = system;
  in
    if priority != null
    then let
      sources = filterAttrs (_key: value: value != null) (genAttrs priority (name: nixpkgs.${name} or null));
    in
      (findFirst
        (nixpkgsSource: nixpkgsSource.legacyPackages.${targetSystem} or null != null)
        nixpkgs.legacyPackages
        (attrValues sources))
      .${
        targetSystem
      }
    else nixpkgs.legacyPackages.${targetSystem};

  /**
  Resolve a package from `pkgs` by trying one or more names in order.

  # Type
  ```nix
  package :: { pkgs :: AttrSet, target :: string | [string], default :: a } -> Derivation | a
  ```

  # Examples
  ```nix
  package { inherit pkgs; target = ["firefox-beta" "firefox-esr" "firefox"]; }
  # => First available variant, or null
  ```
  */
  package = {
    pkgs,
    target,
    default ? null,
  }:
    byPaths {
      attrset = pkgs;
      paths = map (name: [name]) (toList target);
      inherit default;
    };

  /**
  Map a shell name to its nixpkgs package.

  Falls back to `pkgs.bashInteractive` for unknown names.

  # Type
  ```nix
  shellPackage :: { pkgs :: AttrSet, shellName :: string } -> Derivation
  ```

  # Examples
  ```nix
  shellPackage { inherit pkgs; shellName = "zsh"; }      # => pkgs.zsh
  shellPackage { inherit pkgs; shellName = "unknown"; }  # => pkgs.bashInteractive
  ```
  */
  shellPackage = {
    pkgs,
    shellName,
  }:
    {
      "bash" = pkgs.bashInteractive;
      "nushell" = pkgs.nushell;
      "powershell" = pkgs.powershell;
      "zsh" = pkgs.zsh;
      "fish" = pkgs.fish;
    }
    .${
      shellName
    } or pkgs.bashInteractive;

  /**
  Conditionally include a single attribute in an attrset merge.

  Returns `{ name = attrs.name; }` if the attribute exists and is non-empty,
  otherwise returns `{}`. Designed for clean `//` chaining.

  # Type
  ```nix
  optional :: AttrSet -> string -> AttrSet
  ```

  # Examples
  ```nix
  { inherit foo bar; }
  // optional config "baz"
  // optional config "qux"
  ```
  */
  optional = attrs: name:
    if attrs ? name && isNotEmpty attrs.${name}
    then {${name} = attrs.${name};}
    else {};

  flake = {
    self ? {},
    path ? src,
  }: let
    normalizedPath = flakePath {inherit self path;};
    derived = optionalAttrs (normalizedPath != null) (getFlake normalizedPath);
    failureReason =
      if normalizedPath == null
      then "path normalization failed"
      else if derived == null
      then "getFlake returned null"
      else if (derived._type or null) != "flake"
      then "invalid flake type: ${(derived._type or "null")}"
      else "unknown";
  in
    if self != {}
    then self
    else
      traceIf
      ((derived._type or null) != "flake")
      "❌ Flake load failed: ${toString path} (${failureReason})"
      (derived // {srcPath = path;});

  host = {
    nixosConfigurations ? optionalAttrs ((flake {}) ? nixosConfigurations) (flake {}).nixosConfigurations,
    system ? (getSystems {}).system,
  }: let
    derived =
      findFirst
      (hostConfig: (hostConfig.config.nixpkgs.hostPlatform.system or null) == system)
      null
      (attrValues nixosConfigurations);
  in
    traceIf
    ((derived.class or null) != "nixos")
    "❌ Failed to derive current host"
    (derived // {name = derived.config.networking.hostName;});

  nixpkgs = {
    system,
    config,
    overlays,
    inputs,
    ...
  }:
    {
      hostPlatform = system;
      inherit config overlays;
    }
    // (
      with inputs.nixpkgs; (
        if (host.class or "nixos") == "darwin"
        then {source = outPath;}
        else {flake.source = outPath;}
      )
    );

  __doc = ''
    Attribute set resolution and lookup utilities.

    Provides tools for navigating nested structures, handling missing attributes
    gracefully, and resolving values from multiple potential sources.
  '';

  exports = {
    inherit
      byPaths
      flake
      get
      host
      nestedByPaths
      nixpkgs
      optional
      orNull
      package
      packages
      shellPackage
      ;
    getPkgs = packages;
    getPackage = package;
    getShellPackage = shellPackage;
    getAttr = get;
    getAttrByPaths = byPaths;
    getNestedAttrByPaths = nestedByPaths;
    getAttrOrNull = orNull;
    optionalAttr = optional;
    getFlake = flake;
    getHost = host;
  };
in
  exports
  // {
    inherit __doc;
    _rootAliases = {
      inherit
        (exports)
        getPkgs
        getPackage
        getShellPackage
        getAttr
        getAttrByPaths
        getNestedAttrByPaths
        getAttrOrNull
        optionalAttr
        getFlake
        getHost
        ;
    };
  }
