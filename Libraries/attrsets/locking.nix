{lib, ...}: let
  inherit (lib.attrsets) mapAttrs;

  /**
  Lock attribute values with metadata.

  Wraps each value in an attribute set with a specified status and value structure.
  Commonly used for browser policies, configuration management, or any scenario
  where values need to be marked as locked/managed.

  # Type
  ```nix
  lockAttrs :: String -> AttrSet -> AttrSet
  ```

  # Arguments
  - status: The status to apply to all values (e.g., "locked", "managed", "readonly")
  - attrs: The attribute set to transform

  # Examples
  ```nix
  lockAttrs "locked" {
    homepage = "https://example.com";
    searchEngine = "DuckDuckGo";
  }
  # => {
  #   homepage = { Value = "https://example.com"; Status = "locked"; };
  #   searchEngine = { Value = "DuckDuckGo"; Status = "locked"; };
  # }

  # Use for Firefox policies
  lockAttrs "locked" {
    DisableTelemetry = true;
    NoDefaultBookmarks = true;
  }
  # => {
  #   DisableTelemetry = { Value = true; Status = "locked"; };
  #   NoDefaultBookmarks = { Value = true; Status = "locked"; };
  # }
  ```
  */
  lockAttrs = status: attrs:
    mapAttrs (_: value: {
      Value = value;
      Status = status;
    })
    attrs;

  /**
  Lock attributes with "locked" status (convenience wrapper).

  # Type
  ```nix
  makeLockedAttrs :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  makeLockedAttrs {
    homepage = "https://example.com";
    trackingProtection = true;
  }
  # => {
  #   homepage = { Value = "https://example.com"; Status = "locked"; };
  #   trackingProtection = { Value = true; Status = "locked"; };
  # }
  ```
  */
  makeLockedAttrs = lockAttrs "locked";

  /**
  Lock attributes with "managed" status.

  # Type
  ```nix
  makeManagedAttrs :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  makeManagedAttrs {
    proxy = "http://proxy.example.com";
  }
  # => {
  #   proxy = { Value = "http://proxy.example.com"; Status = "managed"; };
  # }
  ```
  */
  makeManagedAttrs = lockAttrs "managed";
in {
  inherit
    lockAttrs
    makeLockedAttrs
    makeManagedAttrs
    ;
}
