{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (_.types.predicates) isString typeOf;
  inherit (_.trivial.tests) mkTest runTests mkThrows;

  /**
  Lock attribute values with metadata.

  Wraps each value in an attribute set with a specified status and value structure.
  Commonly used for browser policies, configuration management, or any scenario
  where values need to be marked as locked/managed.

  # Type
  ```
  lock :: String -> AttrSet -> AttrSet
  ```

  # Arguments
  - `status`: The status to apply to all values (e.g., "locked", "managed", "readonly")
  - `attrs`: The attribute set to transform

  # Returns
  An attribute set where each value is wrapped in `{ Value = <original>; Status = <status>; }`

  # Throws
  - Error if `attrs` is not an attribute set
  - Error if `status` is not a string

  # Examples
  ```nix
  lock "locked" {
    homepage = "https://example.com";
    searchEngine = "DuckDuckGo";
  }
  # => {
  #   homepage = { Value = "https://example.com"; Status = "locked"; };
  #   searchEngine = { Value = "DuckDuckGo"; Status = "locked"; };
  # }

  # Firefox policies example
  lock "locked" {
    DisableTelemetry = true;
    NoDefaultBookmarks = true;
  }
  ```
  */
  lock = status: attrs:
    if !isString status
    then throw "lockAttrs: status must be a string, got ${typeOf status}"
    else if !isAttrs attrs
    then throw "lockAttrs: attrs must be an attribute set, got ${typeOf attrs}"
    else
      mapAttrs (_: value: {
        Value = value;
        Status = status;
      })
      attrs;

  /**
  Lock attributes with "locked" status (convenience wrapper).

  Equivalent to `lock "locked"`. Use when you need immutable configuration
  values that users cannot change.

  # Type
  ```
  locked :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  locked {
    homepage = "https://example.com";
    trackingProtection = true;
  }
  ```
  */
  locked = lock "locked";

  /**
  Lock attributes with "managed" status.

  Equivalent to `lockAttrs "managed"`. Use when configuration is managed by
  an administrator but may allow some user customization depending on the policy engine.

  # Type
  ```
  managed :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  managed {
    proxy = "http://proxy.example.com";
    certificates = [ ./corporate-ca.crt ];
  }
  ```
  */
  managed = lock "managed";
in {
  inherit
    lock
    locked
    managed
    ;

  _rootAliases = {
    lockAttrs = lock;
    makeLockedAttrs = locked;
    makeManagedAttrs = managed;
  };

  _tests = runTests {
    lock = {
      basic = mkTest {
        expected = {
          x = {
            Value = 1;
            Status = "locked";
          };
        };
        expr = lock "locked" {x = 1;};
      };

      nested = mkTest {
        expected = {
          a = {
            Value = {b = 2;};
            Status = "managed";
          };
          c = {
            Value = 3;
            Status = "managed";
          };
        };
        expr = lock "managed" {
          a = {b = 2;};
          c = 3;
        };
      };

      empty = mkTest {
        expected = {};
        expr = lock "locked" {};
      };

      invalidStatus = mkThrows (lock 123 {x = 1;});

      invalidAttrs = mkThrows (lock "locked" "not-an-attrset");
    };

    locked = {
      basic = mkTest {
        expected = {
          enable = {
            Value = true;
            Status = "locked";
          };
        };
        expr = locked {enable = true;};
      };
    };

    managed = {
      basic = mkTest {
        expected = {
          url = {
            Value = "https://example.com";
            Status = "managed";
          };
        };
        expr = managed {url = "https://example.com";};
      };
    };
  };
}
