{
  _,
  lib,
  ...
}: let
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.runners) runTests;
  inherit (_.debug.stubs) mkDefaultStub mkEnableOptionStub mkForceStub;
  inherit (_.types.predicates) isSpecial;
  inherit (lib.attrsets) filterAttrs isAttrs isDerivation mapAttrs;

  /**
  Recursively applies `mkDefault` to all leaf values in an attribute set.

  Preserves special module types (those with `_type`) and derivations unchanged.

  # Type
  ```nix
  update :: a -> a
  ```

  # Examples
  ```nix
  update { enable = true; port = 8080; }
  # => { enable = mkDefault true; port = mkDefault 8080; }

  # Nested attrsets
  update { services.nginx = { enable = true; port = 80; }; }
  # => all leaf values wrapped in mkDefault

  # Preserves special types and derivations unchanged
  update { enable = lib.mkEnableOption "service"; port = 8080; }
  # => { enable = lib.mkEnableOption "service"; port = mkDefault 8080; }
  ```
  */
  update = value:
    if isSpecial value
    then value
    else if isAttrs value && !isDerivation value
    then mapAttrs (_key: update) value
    else mkDefaultStub value;

  /**
  Deep merge two attribute sets with module-aware handling.

  Similar to `lib.recursiveUpdate` but respects module system semantics —
  special types in `prev` are protected from being clobbered, while special
  types in `next` are allowed to override.

  # Type
  ```nix
  updateDeep :: AttrSet -> AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  updateDeep
    { a = 1; b = { c = 2; }; }
    { b = { d = 3; }; e = 4; }
  # => { a = 1; b = { c = 2; d = 3; }; e = 4; }

  # Preserves _type in prev
  updateDeep
    { enable = lib.mkEnableOption "foo"; }
    { enable = true; }
  # => { enable = lib.mkEnableOption "foo"; }  # prev special type wins

  # Allows _type override from next
  updateDeep
    { enable = true; }
    { enable = lib.mkForce false; }
  # => { enable = lib.mkForce false; }          # next special type wins
  ```
  */
  updateDeep = prev: next:
    if isSpecial prev
    then prev
    else if isSpecial next
    then next
    else if isAttrs prev && isAttrs next && !isDerivation prev && !isDerivation next
    then
      mapAttrs
      (name: prevValue:
        if next ? ${name}
        then let
          nextValue = next.${name};
        in
          if isSpecial prevValue
          then prevValue
          else if isSpecial nextValue
          then nextValue
          else updateDeep prevValue nextValue
        else prevValue)
      prev
      // filterAttrs (name: _value: !prev ? ${name}) next
    else next;
in {
  inherit
    update
    updateDeep
    ;

  _tests = runTests {
    update = {
      wrapsPrimitives = mkTest {
        desired = {
          a = mkDefaultStub 1;
          b = mkDefaultStub "x";
          c = mkDefaultStub true;
        };
        outcome = update {
          a = 1;
          b = "x";
          c = true;
        };
      };

      recursesIntoNestedSets = mkTest {
        desired = {
          services.nginx = {
            enable = mkDefaultStub true;
            port = mkDefaultStub 8080;
          };
        };
        outcome = update {
          services.nginx = {
            enable = true;
            port = 8080;
          };
        };
      };

      preservesSpecialType = mkTest {
        desired = mkEnableOptionStub "service";
        outcome = update (mkEnableOptionStub "service");
      };
    };

    updateDeep = {
      mergesSimpleAttrs = mkTest {
        desired = {
          a = 1;
          b = {
            c = 2;
            d = 3;
          };
          e = 4;
        };
        outcome =
          updateDeep
          {
            a = 1;
            b = {c = 2;};
          }
          {
            b = {d = 3;};
            e = 4;
          };
      };

      preservesPrevSpecialType = mkTest {
        desired = {enable = mkEnableOptionStub "foo";};
        outcome =
          updateDeep
          {enable = mkEnableOptionStub "foo";}
          {enable = true;};
      };

      allowsNextSpecialType = mkTest {
        desired = {enable = mkForceStub false;};
        outcome =
          updateDeep
          {enable = true;}
          {enable = mkForceStub false;};
      };

      mergesModuleArgsShallow = mkTest {
        desired = {
          _module = {
            args = {
              x = 1;
              y = 2;
            };
          };
        };
        outcome =
          updateDeep
          {_module = {args = {x = 1;};};}
          {_module = {args = {y = 2;};};};
      };

      primitiveOverride = mkTest {
        desired = 2;
        outcome = updateDeep 1 2;
      };
    };
  };
}
