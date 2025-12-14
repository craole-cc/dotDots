{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) hasAttrByPath attrByPath;
  inherit (lib.lists) filter head toList;
  inherit (_.predicates) isNotEmpty;

  /**
  Get an attribute by trying multiple paths.

  Searches through a list of possible attribute paths and returns the first match.
  Useful when an attribute might be named differently across configurations.

  # Type
  ```nix
  getByPaths :: AttrSet -> [[String]] -> a -> a
  ```

  # Arguments
  - `attrset`: The attribute set to search
  - `paths`: List of attribute paths to try (each path is a list of strings)
  - `default`: Optional default value if no paths match

  # Returns
  The value at the first matching path, or the default value if no paths match.

  # Examples
  ```nix
  getByPaths {
    attrset = { foo.bar = 1; baz.qux = 2; };
    paths = [["missing"] ["foo" "bar"] ["baz" "qux"]];
    default = null;
  }
  # => 1 (first match)

  getByPaths {
    attrset = pkgs;
    paths = [["firefox-beta"] ["firefox-esr"] ["firefox"]];
    default = null;
  }
  # => pkgs.firefox-beta or pkgs.firefox-esr or pkgs.firefox
  ```
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
  Get a package from pkgs by trying multiple names.

  Convenience wrapper around `getByPaths` for package resolution.
  Tries multiple package names and returns the first available.

  # Type
  ```nix
  getPackage :: { pkgs :: AttrSet, target :: StringOrList, default :: a } -> a
  getPackage :: { pkgs :: AttrSet, target :: String \| [String], default ? a } -> a
  ```

  # Arguments
  An attribute set with:
  - `pkgs`: The nixpkgs package set
  - `target`: Single package name or list of package names to try
  - `default`: Optional default value if no names match

  # Returns
  The first matching package, or the default value if no names match.

  # Examples
  ```nix
  getPackage {
    inherit pkgs;
    target = "firefox-beta";
  }
  # => pkgs.firefox-beta or null

  getPackage {
    inherit pkgs;
    target = ["firefox-beta" "firefox-esr" "firefox"];
  }
  # => First available variant

  getPackage {
    inherit pkgs;
    target = ["nonexistent" "firefox"];
    default = pkgs.chromium;
  }
  # => pkgs.firefox (or pkgs.chromium if firefox missing)
  ```
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
      # Add more shells as needed
    }.${
      shellName
    } or pkgs.bashInteractive;
  /**
  Get a nested attribute by trying multiple parent names.

  Useful for finding homeModules, nixosModules, or other nested attributes
  where the parent name might vary.

  # Type
  ```nix
  getNestedAttr :: {
    attrset :: AttrSet,
    parentNames :: StringOrList,
    childName :: String,
    default :: a
  } -> a
  ```

  # Arguments
  An attribute set with:
  - `attrset`: The attribute set to search
  - `parentNames`: Single name or list of possible parent attribute names
  - `childName`: The nested attribute name to access
  - `default`: Optional default value if no parent/child combination exists

  # Returns
  The nested attribute from the first matching parent, or the default value.

  # Examples
  ```nix
  getNestedAttr {
    attrset = inputs;
    parentNames = ["zenBrowser" "zen-browser" "zen"];
    childName = "homeModules";
    default = null;
  }
  # => inputs.zenBrowser.homeModules (if exists)

  getNestedAttr {
    attrset = inputs;
    parentNames = "alice";
    childName = "nixosModules";
    default = {};
  }
  # => inputs.alice.nixosModules or {}
  ```
  */
  getNestedAttr = {
    attrset,
    parentNames,
    childName,
    default ? {},
  }: let
    parentList = toList parentNames;
    paths = map (parent: [parent childName]) parentList;
  in
    getByPaths {inherit attrset paths default;};
in {
  inherit
    getByPaths
    getPackage
    getNestedAttr
    ;
}
