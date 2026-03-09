{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest mkThrows;
  inherit (_.debug.runners) runTests;
  inherit (_.types.predicates) isString typeOf;
  inherit (lib.attrsets) isAttrs mapAttrs;

  /**
  Lock attribute values with metadata.

  Wraps each value in an attribute set with a specified status and value structure.
  Commonly used for browser policies, configuration management, or any scenario
  where values need to be marked as locked/managed.

  # Type
  ```nix
  lock :: string -> AttrSet -> AttrSet
  ```

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
  ```
  */
  lock = status: attrs:
    if !isString status
    then throw "lockAttrs: status must be a string, got ${typeOf status}"
    else if !isAttrs attrs
    then throw "lockAttrs: attrs must be an attribute set, got ${typeOf attrs}"
    else
      mapAttrs (_key: value: {
        Value = value;
        Status = status;
      })
      attrs;

  /**
  Lock attributes with "locked" status (convenience wrapper).

  Equivalent to `lock "locked"`.

  # Type
  ```nix
  locked :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  locked { homepage = "https://example.com"; trackingProtection = true; }
  ```
  */
  locked = lock "locked";

  /**
  Lock attributes with "managed" status (convenience wrapper).

  Equivalent to `lock "managed"`.

  # Type
  ```nix
  managed :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  managed { proxy = "http://proxy.example.com"; }
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
        desired = {
          x = {
            Value = 1;
            Status = "locked";
          };
        };
        outcome = lock "locked" {x = 1;};
      };

      nested = mkTest {
        desired = {
          a = {
            Value = {b = 2;};
            Status = "managed";
          };
          c = {
            Value = 3;
            Status = "managed";
          };
        };
        outcome = lock "managed" {
          a = {b = 2;};
          c = 3;
        };
      };

      empty = mkTest {
        desired = {};
        outcome = lock "locked" {};
      };

      invalidStatus = mkThrows (lock 123 {x = 1;});
      invalidAttrs = mkThrows (lock "locked" "not-an-attrset");
    };

    locked = {
      basic = mkTest {
        desired = {
          enable = {
            Value = true;
            Status = "locked";
          };
        };
        outcome = locked {enable = true;};
      };
    };

    managed = {
      basic = mkTest {
        desired = {
          url = {
            Value = "https://example.com";
            Status = "managed";
          };
        };
        outcome = managed {url = "https://example.com";};
      };
    };
  };
}
