{lib, ...}: let
  inherit (lib.attrsets) isAttrs mapAttrs;
  inherit (lib.strings) isString typeOf;
  inherit (builtins) tryEval;

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

  mkLocked = lock "locked";
  mkManaged = lock "managed";
in {
  inherit
    lock
    mkLocked
    mkManaged
    ;

  _rootAliases = {
    lockAttrs = lock;
    mkLockedAttrs = mkLocked;
    mkManagedAttrs = mkManaged;
  };

  _tests = lib.runTests {
    lockBasic = {
      expr = lock "locked" {x = 1;};
      expected = {
        x = {
          Value = 1;
          Status = "locked";
        };
      };
    };

    lockNested = {
      expr = lock "managed" {
        a = {b = 2;};
        c = 3;
      };
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
    };

    mkLocked = {
      expr = mkLocked {enable = true;};
      expected = {
        enable = {
          Value = true;
          Status = "locked";
        };
      };
    };

    mkManaged = {
      expr = mkManaged {url = "https://example.com";};
      expected = {
        url = {
          Value = "https://example.com";
          Status = "managed";
        };
      };
    };

    lockEmpty = {
      expr = lock "locked" {};
      expected = {};
    };

    lockInvalidStatus = {
      expr = tryEval (lock 123 {x = 1;});
      expected = {
        success = false;
        value = false;
      };
    };

    lockInvalidAttrs = {
      expr = tryEval (lock "locked" "not-an-attrset");
      expected = {
        success = false;
        value = false;
      };
    };
  };
}
