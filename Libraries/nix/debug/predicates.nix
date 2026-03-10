{_, ...}: let
  inherit (_.attrsets.predicates) isAttrs;

  /**
  Check whether a value is a test result record produced by `mkTest`.

  A test record has `desired`, `result`, and `passed` fields.

  # Type
  ```nix
  isTest :: any -> bool
  ```
  */
  isTest = v:
    isAttrs v
    && v ? desired
    && v ? result
    && v ? passed;

  exports = {
    inherit
      isTest
      ;
  };
in
  exports // {_rootAliases = exports;}
