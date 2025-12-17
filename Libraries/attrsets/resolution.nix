{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) hasAttrByPath attrByPath;
  inherit (lib.lists) filter head toList;
  inherit (_) isNotEmpty;

  /**
  Get an attribute by trying multiple paths.

  Searches through a list of possible attribute paths in order and returns
  the value at the first matching path. Useful for handling attributes that
  might be named differently across versions, configurations, or systems.

  # Type
  ```
  getByPaths :: { attrset :: AttrSet, paths :: [[String]], default :: a } -> a
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The attribute set to search
  - `paths`: List of attribute paths to try (each path is a list of strings)
  - `default`: Value to return if no paths exist (default: `{}`)

  # Returns
  The value at the first matching path, or `default` if no paths match.

  # Examples
  ```nix
  getByPaths {
    attrset = { foo.bar = 1; baz.qux = 2; };
    paths = [["missing"] ["foo" "bar"] ["baz" "qux"]];
    default = null;
  }
  # => 1 (first match: foo.bar)

  getByPaths {
    attrset = pkgs;
    paths = [["firefox-beta"] ["firefox-esr"] ["firefox"]];
  }
  # => pkgs.firefox-beta (if exists) or pkgs.firefox-esr or pkgs.firefox

  # No matches
  getByPaths {
    attrset = {};
    paths = [["a"] ["b"]];
    default = "fallback";
  }
  # => "fallback"
  ```

  # Use Cases
  - Multi-version package selection (beta, stable, LTS)
  - Cross-platform attribute resolution
  - Configuration migration (old name -> new name)
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

  Searches for a child attribute under different possible parent attributes.
  Useful for finding modules, configs, or nested structures where the parent
  name might vary (e.g., different flake input naming conventions).

  # Type
  ```
  getNestedAttr :: {
    attrset :: AttrSet,
    parentNames :: String | [String],
    childName :: String,
    default :: a
  } -> a
  ```

  # Arguments
  An attribute set containing:
  - `attrset`: The attribute set to search
  - `parentNames`: Single name or list of possible parent attribute names
  - `childName`: The nested attribute name to access under each parent
  - `default`: Value to return if no parent/child combination exists (default: `{}`)

  # Returns
  The nested attribute from the first matching parent, or `default`.

  # Examples
  ```nix
  # Flake input with varying names
  getNestedAttr {
    attrset = inputs;
    parentNames = ["zenBrowser" "zen-browser" "zen"];
    childName = "homeModules";
  }
  # => inputs.zenBrowser.homeModules (if exists)
  #    or inputs.zen-browser.homeModules
  #    or inputs.zen.homeModules
  #    or {}

  # Single parent name
  getNestedAttr {
    attrset = inputs;
    parentNames = "home-manager";
    childName = "nixosModules";
    default = null;
  }
  # => inputs.home-manager.nixosModules or null

  # Config resolution
  getNestedAttr {
    attrset = config;
    parentNames = ["services" "systemd"];
    childName = "units";
    default = [];
  }
  # => config.services.units or config.systemd.units or []
  ```

  # Use Cases
  - Flake input module resolution (homeModules, nixosModules)
  - Handling renamed/aliased configuration paths
  - Finding nested options in varying config structures
  */
  getNestedByPaths = {
    attrset,
    parents,
    target,
    default ? {},
  }:
    map (parent: parent target) (toList parents);
  # getByPaths {
  #   inherit attrset default;
  #   paths = map (parent: [parent target]) (toList paths);
  # };

  /**
  Get a package from pkgs by trying multiple names.

  Convenience wrapper around `getByPaths` for package resolution. Tries
  package names in order and returns the first available one. Handles both
  single package names and lists of alternatives.

  # Type
  ```
  getPackage :: { pkgs :: AttrSet, target :: String | [String], default :: a } -> a
  ```

  # Arguments
  An attribute set containing:
  - `pkgs`: The nixpkgs package set (or any attrset containing packages)
  - `target`: Single package name or list of package names to try in order
  - `default`: Value to return if none match (default: `null`)

  # Returns
  The first available package, or `default` if none exist.

  # Examples
  ```nix
  # Single target
  getPackage {
    inherit pkgs;
    target = "firefox-beta";
  }
  # => pkgs.firefox-beta (if exists) or null

  # Multiple alternatives
  getPackage {
    inherit pkgs;
    target = ["firefox-beta" "firefox-esr" "firefox"];
  }
  # => First available variant

  # With custom default
  getPackage {
    inherit pkgs;
    target = ["nonexistent" "firefox"];
    default = pkgs.chromium;
  }
  # => pkgs.firefox (if exists) or pkgs.chromium

  # Version preference
  getPackage {
    inherit pkgs;
    target = ["python312" "python311" "python310" "python3"];
  }
  # => Newest available Python 3.x
  ```

  # Use Cases
  - Feature branch / stable fallback selection
  - Cross-architecture package naming differences
  - Graceful degradation for optional dependencies
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

  Maps common shell names to their corresponding nixpkgs packages. Provides
  a consistent interface for shell selection across configurations.

  # Type
  ```
  getShellPackage :: { pkgs :: AttrSet, shellName :: String } -> Derivation
  ```

  # Arguments
  An attribute set containing:
  - `pkgs`: The nixpkgs package set
  - `shellName`: Name of the shell ("bash", "zsh", "fish", etc.)

  # Returns
  The corresponding shell package, or `pkgs.bashInteractive` if shell name
  is not recognized.

  # Examples
  ```nix
  getShellPackage { inherit pkgs; shellName = "zsh"; }
  # => pkgs.zsh

  getShellPackage { inherit pkgs; shellName = "fish"; }
  # => pkgs.fish

  getShellPackage { inherit pkgs; shellName = "unknown"; }
  # => pkgs.bashInteractive (fallback)
  ```

  # Supported Shells
  - bash (bashInteractive)
  - nushell
  - powershell
  - zsh
  - fish

  # Notes
  - Always returns a valid package (never null)
  - Extend by adding entries to the internal mapping
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
in {
  inherit
    getByPaths
    getNestedByPaths
    getPackage
    getShellPackage
    ;

  _rootAliases = {
    inherit getPackage getShellPackage;
    getAttrByPaths = getByPaths;
    getNestedAttrByPaths = getNestedByPaths;
  };
}
