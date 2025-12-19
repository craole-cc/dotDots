{
  _,
  lib,
  ...
}: let
  inherit (builtins) readFile tryEval getFlake fromJSON;
  inherit (lib.attrsets) hasAttrByPath attrByPath attrNames optionalAttrs;
  inherit (lib.lists) filter head toList findFirst;
  inherit (lib.trivial) pathExists;
  inherit (lib.srings) removeSuffix;
  inherit (_) isNotEmpty isFlakePath normalizeFlakePath;

  /**
  Get attribute or default if missing/empty.

  Safely access an attribute with automatic emptiness checking and fallback.
  Eliminates the need for `attrs.key or null` patterns combined with
  manual emptiness checks.

  # Type
  ```
  get :: AttrSet -> String -> a -> a
  ```

  # Arguments
  - `attrs`: The attribute set to query
  - `name`: The attribute name to access
  - `default`: Fallback value if attribute is missing or empty

  # Returns
  `attrs.${name}` if it exists and is non-empty, otherwise `default`

  # Examples
  ```nix
  get { a = "hello"; } "a" "fallback"       # => "hello"
  get { a = ""; } "a" "fallback"            # => "fallback" (empty)
  get {} "a" "fallback"                     # => "fallback" (missing)
  get { a = 0; } "a" 42                     # => 0 (numbers never empty)
  get { a = false; } "a" true               # => false (bools never empty)
  get { a = []; } "a" [1 2]                 # => [1 2] (empty list)

  # Real-world usage
  package = get zen "package" (getPackage {
    inherit pkgs;
    target = detectedVariant;
  });
  ```

  # Use Cases
  - Configuration option access with defaults
  - Optional module parameters
  - User preferences with system fallbacks
  - Safe navigation of potentially incomplete data structures

  # Notes
  - Uses `isEmpty` from emptiness.nix for consistent empty checking
  - Only accesses the attribute once (efficient)
  - Replaces verbose `if attrs ? name && isNotEmpty attrs.name then ...`
  */
  get = attrs: name: default:
    if attrs ? ${name} && isNotEmpty attrs.${name}
    then attrs.${name}
    else default;

  /**
  Get attribute or default if missing (null check only).

  Like `get` but only checks attribute existence, not emptiness.
  Use when you want to preserve empty values as-is.

  # Type
  ```
  getOrNull :: AttrSet -> String -> a -> a
  ```

  # Arguments
  - `attrs`: The attribute set to query
  - `name`: The attribute name to access
  - `default`: Fallback value if attribute doesn't exist

  # Returns
  `attrs.${name}` if it exists (even if empty), otherwise `default`

  # Examples
  ```nix
  getOrNull { a = ""; } "a" "fallback"      # => "" (exists, even if empty)
  getOrNull { a = []; } "a" [1]             # => [] (exists, even if empty)
  getOrNull {} "a" "fallback"               # => "fallback" (missing)
  getOrNull { a = null; } "a" "fallback"    # => null (exists)
  ```

  # Use Cases
  - Distinguishing unset attributes from explicitly empty ones
  - Preserving empty strings, lists, or attrsets that have semantic meaning
  - API responses where `missing` differs from `empty`
  */
  getOrNull = attrs: name: default:
    if attrs ? ${name}
    then attrs.${name}
    else default;

  /**
  Get an attribute by trying multiple paths.

  Search through a list of attribute paths in order, returning the value
  at the first path that exists. Enables flexible attribute resolution
  across varying structures, versions, or naming conventions.

  # Type
  ```
  getByPaths :: {
    attrset :: AttrSet,
    paths :: [[String]],
    default :: a
  } -> a
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The attribute set to search
  - `paths`: List of attribute paths to try (each path is a list of strings)
  - `default`: Value to return if no paths match (default: `{}`)

  # Returns
  The value at the first matching path, or `default` if no paths exist

  # Examples
  ```nix
  # Simple multi-path lookup
  getByPaths {
    attrset = { foo.bar = 1; baz.qux = 2; };
    paths = [["missing"] ["foo" "bar"] ["baz" "qux"]];
    default = null;
  }
  # => 1 (first match: foo.bar)

  # Package variant selection
  getByPaths {
    attrset = pkgs;
    paths = [["firefox-beta"] ["firefox-esr"] ["firefox"]];
  }
  # => pkgs.firefox-beta (if exists), else firefox-esr, else firefox

  # Configuration migration
  getByPaths {
    attrset = config;
    paths = [
      ["services" "myapp" "v2" "enable"]  # New path
      ["services" "myapp" "enable"]        # Old path
    ];
    default = false;
  }

  # No matches
  getByPaths {
    attrset = {};
    paths = [["a"] ["b"]];
    default = "fallback";
  }
  # => "fallback"
  ```

  # Use Cases
  - Multi-version package selection (beta → stable → LTS)
  - Cross-platform attribute resolution (linux.x86_64 → linux.aarch64)
  - Configuration migration paths (v2 → v1 → legacy)
  - Flake input variations (different naming conventions)

  # Notes
  - Stops at first matching path (lazy evaluation)
  - Path order determines precedence
  - Uses `lib.attrsets.hasAttrByPath` for existence checks
  */
  getByPaths = {
    attrset,
    paths,
    default ? {},
  }: let
    check = path: hasAttrByPath path attrset;
    matched = filter check paths;
  in
    if isNotEmpty matched
    then attrByPath (head matched) default attrset
    else default;

  /**
  Get a nested attribute by trying multiple parent names.

  Search for a child attribute under various possible parent attributes.
  Particularly useful for flake inputs where the input name may vary but
  the nested structure is consistent.

  # Type
  ```
  getNestedByPaths :: {
    attrset :: AttrSet,
    parents :: String | [String],
    target :: String | [String],
    default :: a
  } -> a
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The attribute set to search
  - `parents`: Single name or list of possible parent attribute names
  - `target`: Child attribute path (string or list) under each parent
  - `default`: Value to return if no parent/child combo exists (default: `{}`)

  # Returns
  The nested attribute from the first matching parent, or `default`

  # Examples
  ```nix
  # Flake input with varying names
  getNestedByPaths {
    attrset = inputs;
    parents = ["zenBrowser" "zen-browser" "zen"];
    target = "homeModules";
  }
  # => inputs.zenBrowser.homeModules (if exists)
  #    or inputs.zen-browser.homeModules
  #    or inputs.zen.homeModules
  #    or {}

  # Deeper nesting with list target
  getNestedByPaths {
    attrset = inputs;
    parents = ["home-manager" "hm"];
    target = ["nixosModules" "default"];
    default = null;
  }
  # => inputs.home-manager.nixosModules.default
  #    or inputs.hm.nixosModules.default
  #    or null

  # Single parent name (still works)
  getNestedByPaths {
    attrset = config;
    parents = "services";
    target = ["myapp" "enable"];
    default = false;
  }
  # => config.services.myapp.enable or false

  # Multiple possible config locations
  getNestedByPaths {
    attrset = config;
    parents = ["services" "systemd"];
    target = "units";
    default = [];
  }
  # => config.services.units or config.systemd.units or []
  ```

  # Use Cases
  - Flake input module resolution with name variations
  - Handling renamed/aliased configuration paths
  - Finding nested options in varying config structures
  - Cross-version compatibility layers

  # Notes
  - Automatically converts single values to lists
  - Combines parent names with target path(s) internally
  - Delegates to `getByPaths` for the actual resolution
  */
  getNestedByPaths = {
    attrset,
    parents,
    target,
    default ? {},
  }:
    getByPaths {
      inherit attrset default;
      paths = map (parent: [parent] ++ toList target) (toList parents);
    };

  /**
  Get the target system string with appropriate fallbacks.

  # Type
  getSystem :: AttrSet -> String

  # Arguments
  - `system` (optional): Target system string. If provided, this is returned directly.

  # Returns
  The system string, determined in this order:
  1. The provided `system` argument (if not null)
  2. `builtins.currentSystem` (when available)
  3. `"x86_64-linux"` (as the final fallback)

  # Examples
  ```nix
  # Explicit system
  getSystem { system = "aarch64-darwin"; }  # Returns: "aarch64-darwin"

  # Use current system
  getSystem {}  # Returns: builtins.currentSystem or "x86_64-linux"

  # When builtins.currentSystem is not available
  getSystem {}  # Returns: "x86_64-linux" (fallback)
  ```

  # Notes
  - Useful for functions that need system information but accept an optional override
  - Handles the edge case where builtins.currentSystem might not be available
  */
  getSystem = {system ? null}: let
    currentSystem =
      if system != null # ← FIXED: Check for null, not truthiness
      then system
      else (builtins.currentSystem or "x86_64-linux");
  in
    currentSystem;

  /**
  Get nixpkgs for the specified system or the current system.

  # Type
  getPkgs :: AttrSet -> AttrSet

  # Arguments
  nixpkgs (optional): Nixpkgs flake to use (defaults to <nixpkgs>)
  system (optional): Target system string. Uses getSystem for fallback logic.

  # Returns
  The legacyPackages set for the determined system from the given nixpkgs.

  # Examples
  ```nix
  # Get nixpkgs for x86_64-linux
  getPkgs { system = "x86_64-linux"; }

  # Get nixpkgs for current system
  getPkgs {}

  # Get nixpkgs for aarch64-darwin with custom nixpkgs
  getPkgs {
    nixpkgs = import <nixpkgs-unstable>;
    system = "aarch64-darwin";
  }

  # Get nixpkgs using getSystem's fallback logic
  getPkgs { nixpkgs = import ./my-nixpkgs.nix; }
  ```
  # Notes
  - Uses getSystem internally for system determination
  - Uses nixpkgs.legacyPackages.${system} to access packages
  - Delegates fallback logic to getSystem for consistency
  */
  getPkgs = {
    nixpkgs ? import <nixpkgs>,
    system ? null,
  }: let
    targetSystem = getSystem {inherit system;};
  in
    nixpkgs.legacyPackages.${targetSystem};

  /**
  Get a package from pkgs by trying multiple names.

  Convenience wrapper for package resolution. Tries package names in order
  and returns the first available one. Handles both single names and lists
  of alternatives with automatic fallback logic.

  # Type
  ```
  getPackage :: {
    pkgs :: AttrSet,
    target :: String | [String],
    default :: a
  } -> Derivation | a
  ```

  # Arguments
  An attribute set containing:
  - `pkgs`: The nixpkgs package set (or any attrset containing packages)
  - `target`: Single package name or list of package names to try in order
  - `default`: Value to return if none match (default: `null`)

  # Returns
  The first available package derivation, or `default` if none exist

  # Examples
  ```nix
  # Single target
  getPackage {
    inherit pkgs;
    target = "firefox-beta";
  }
  # => pkgs.firefox-beta (if exists) or null

  # Multiple alternatives (feature branch → stable)
  getPackage {
    inherit pkgs;
    target = ["firefox-beta" "firefox-esr" "firefox"];
  }
  # => First available variant

  # With custom default
  getPackage {
    inherit pkgs;
    target = ["nonexistent-browser" "firefox"];
    default = pkgs.chromium;
  }
  # => pkgs.firefox (if exists) or pkgs.chromium

  # Version preference (newest available)
  getPackage {
    inherit pkgs;
    target = ["python312" "python311" "python310" "python3"];
  }
  # => Newest available Python 3.x

  # Real-world: Firefox variant resolution
  package = getPackage {
    inherit pkgs;
    target = detectedVariant;  # Could be "firefox-beta" or "firefox"
    default = pkgs.firefox;
  };
  ```

  # Use Cases
  - Feature branch / stable fallback selection
  - Cross-architecture package naming differences
  - Graceful degradation for optional dependencies
  - Browser/editor variant selection (beta, dev, stable)

  # Notes
  - Returns `null` by default if no packages match
  - Handles both string and list inputs automatically
  - Order in list determines precedence
  */
  getPackage = {
    pkgs,
    target,
    default ? null,
  }: let
    nameList = toList target;
    paths = map (name: [name]) nameList;
  in
    getByPaths {
      attrset = pkgs;
      inherit paths default;
    };

  /**
  Get a shell package from a shell name string.

  Map common shell names to their corresponding nixpkgs packages. Provides
  a consistent interface for shell selection across system and user configs.

  # Type
  ```
  getShellPackage :: {
    pkgs :: AttrSet,
    shellName :: String
  } -> Derivation
  ```

  # Arguments
  An attribute set containing:
  - `pkgs`: The nixpkgs package set
  - `shellName`: Name of the shell (case-sensitive)

  # Returns
  The corresponding shell package derivation. Always returns a valid package,
  defaulting to `pkgs.bashInteractive` for unknown names.

  # Supported Shells
  - `"bash"` → `pkgs.bashInteractive`
  - `"nushell"` → `pkgs.nushell`
  - `"powershell"` → `pkgs.powershell`
  - `"zsh"` → `pkgs.zsh`
  - `"fish"` → `pkgs.fish`

  # Examples
  ```nix
  getShellPackage { inherit pkgs; shellName = "zsh"; }
  # => pkgs.zsh

  getShellPackage { inherit pkgs; shellName = "fish"; }
  # => pkgs.fish

  getShellPackage { inherit pkgs; shellName = "unknown"; }
  # => pkgs.bashInteractive (fallback)

  # Real-world: user shell configuration
  users.users.myuser.shell = getShellPackage {
    inherit pkgs;
    shellName = config.preferences.shell or "bash";
  };
  ```

  # Use Cases
  - User shell configuration from preferences
  - Dynamic shell selection in development environments
  - Cross-platform shell abstraction
  - Default shell fallback handling

  # Notes
  - Always returns a valid package (never null)
  - Case-sensitive shell name matching
  - To add support for new shells, extend the internal mapping
  - Uses bash as universal fallback (most compatible)
  */
  getShellPackage = {
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
    }
    or pkgs.bashInteractive;

  /**
  Conditionally include an attribute in an attrset merge.

  Create a single-attribute set if the attribute exists and is non-empty,
  otherwise return an empty set. Designed for clean conditional merging
  using the `//` operator.

  # Type
  ```
  optional :: AttrSet -> String -> AttrSet
  ```

  # Arguments
  - `attrs`: The source attribute set
  - `name`: The attribute name to conditionally include

  # Returns
  `{ name = attrs.name; }` if attribute exists and is non-empty, else `{}`

  # Examples
  ```nix
  # Basic usage
  optional { a = "hello"; } "a"     # => { a = "hello"; }
  optional { a = ""; } "a"          # => {}
  optional {} "a"                   # => {}
  optional { a = null; } "a"        # => {}

  # In attrset merges
  {
    inherit foo bar;
  }
  // optional config "baz"
  // optional config "qux"
  # Clean alternative to:
  # // (if config ? baz && isNotEmpty config.baz
  #     then { inherit (config) baz; }
  #     else {})

  # Real-world: conditional module inclusion
  {
    inherit program package allowed;
    variant = detectedVariant;
  }
  // optional zen "module"
  # Only includes `module` attribute if zen.module exists and is non-empty
  ```

  # Use Cases
  - Conditional attribute inclusion in configuration merges
  - Optional module parameters
  - Dynamic attrset construction based on availability
  - Clean alternative to nested conditionals in attrset definitions

  # Notes
  - Returns empty set (not null) for easy merging with `//`
  - Uses `isEmpty` for consistent emptiness checking
  - Particularly useful with optional flake modules or features
  - Can chain multiple optionals: `{} // optional a "x" // optional b "y"`
  */
  optional = attrs: name:
    if attrs ? ${name} && isNotEmpty attrs.${name}
    then {${name} = attrs.${name};}
    else {};

  readRegistry = registryPath:
    if pathExists registryPath
    then let
      content = readFile registryPath;
      parsed = tryEval (fromJSON content);
    in
      if parsed.success
      then parsed.value
      else {
        flakes = [];
        version = 0;
      }
    else {
      flakes = [];
      version = 0;
    };

  # Load traditional NixOS configuration (non-flake)
  loadConfig = configPath:
    if pathExists configPath
    then import configPath
    else {};

  # Load configuration from flake
  loadFlake = {
    path ? null,
    hostName ? null,
    registryPath ? "/etc/nix/registry.json",
  }: let
    # Helper to get flake from path or registry
    getFlakeFromPathOrRegistry = {
      path ? null,
      registryPath ? "/etc/nix/registry.json",
    }: let
      #> Try direct path first
      fromPath =
        if path != null && isFlakePath path
        then let
          normalized = normalizeFlakePath path;
          result = tryEval (getFlake normalized);
        in
          with result;
            if success
            then value
            else {}
        else {};

      # Fall back to registry for "self"
      fromRegistry =
        if fromPath == {}
        then let
          registry = readRegistry registryPath;
          selfFlake =
            findFirst
            (f: f.from.id == "self")
            null
            (registry.flakes or []);
        in
          if selfFlake != null
          then let
            result = tryEval (getFlake selfFlake.to.path);
          in
            with result;
              if success
              then value
              else {}
          else {}
        else {};
    in
      if fromPath != {}
      then fromPath
      else fromRegistry;

    flake = getFlakeFromPathOrRegistry {inherit path registryPath;};

    extractConfig = flake:
      if flake == {}
      then {}
      else if flake ? nixosConfigurations
      then let
        hostFile = "/etc/hostname";
        host =
          if hostName != null
          then hostName
          else
            (
              if pathExists hostFile
              then removeSuffix "\n" (readFile hostFile)
              else null
            );

        configs = flake.nixosConfigurations;
        hosts = attrNames configs;
      in
        if configs == {}
        then {}
        else if host != null && configs ? ${host}
        then configs.${host}
        else configs.${head hosts}
      else {};
  in
    extractConfig flake;

  getFlakeOrConfig = {
    path ? null,
    hostname ? null,
    registryPath ? "/etc/nix/registry.json",
    configPath ? "/etc/nixos/configuration.nix",
  }: let
    #> Try to get configuration from flake first
    fromFlake = loadFlake {
      inherit path hostname registryPath;
    };

    #> If no flake config, try traditional configuration
    fromTraditional =
      if fromFlake == {}
      then loadConfig configPath
      else {};
  in
    if fromFlake != {}
    then fromFlake
    else fromTraditional;

  exports = {
    inherit
      get
      getOrNull
      getByPaths
      getNestedByPaths
      getPkgs
      getPackage
      getShellPackage
      optional
      getFlakeOrConfig
      ;
  };
in
  exports
  // {
    __doc = ''
      Advanced attribute set resolution and lookup utilities.

      This module provides powerful tools for navigating complex nested structures,
      handling missing attributes gracefully, and resolving values from multiple
      potential sources. Essential for configuration management, package selection,
      and flake input handling.

      # Key Features:
      - Multi-path attribute resolution with fallbacks
      - Nested attribute lookup with parent alternatives
      - Package resolution by name(s) with versioning support
      - Conditional attribute inclusion in merges
    '';
    _rootAliases = {
      inherit getPkgs getPackage getShellPackage getFlakeOrConfig;
      getAttr = get;
      getAttrByPaths = getByPaths;
      getNestedAttrByPaths = getNestedByPaths;
      getAttrOrNull = getOrNull;
      optionalAttr = optional;
    };
  }
