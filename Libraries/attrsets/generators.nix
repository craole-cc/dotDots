{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (lib.strings) isString typeOf;
  inherit (builtins) tryEval;
  inherit (_.testing.unit) mkTest runTests;

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
        x = {
          Value = 1;
          Status = "locked";
        };
      } (lock "locked" {x = 1;});

      nested =
        mkTest {
          a = {
            Value = {b = 2;};
            Status = "managed";
          };
          c = {
            Value = 3;
            Status = "managed";
          };
        } (lock "managed" {
          a = {b = 2;};
          c = 3;
        });

      empty = mkTest {} (lock "locked" {});

      invalidStatus = mkTest {
        expr = tryEval (lock 123 {x = 1;});
        expected = {
          success = false;
          value = false;
        };
      };

      invalidAttrs = mkTest {
        expr = tryEval (lock "locked" "not-an-attrset");
        expected = {
          success = false;
          value = false;
        };
      };
    };

    locked = {
      basic = mkTest {
        enable = {
          Value = true;
          Status = "locked";
        };
      } (locked {enable = true;});
    };

    managed = {
      basic = mkTest {
        url = {
          Value = "https://example.com";
          Status = "managed";
        };
      } (managed {url = "https://example.com";});
    };
  };
}
