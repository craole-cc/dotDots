# Test case constructors.
# Use mkTest for documented tests, mkTest' for terse one-liners.
{lib, ...}: let
  inherit (lib) deepSeq;
  inherit (lib.debug) addErrorContext;
  inherit (builtins) tryEval;

  _build = desired: outcome: command: let
    value = deepSeq outcome outcome;
  in {
    inherit desired command;
    result = value;
    passed = desired == value;
  };

  assertMsgFunc = {
    name,
    assertion,
    message,
  }: let
    inherit (lib.asserts) assertMsg;
  in
    assertMsg assertion "${name}: ${message}";

  withContext = {
    name,
    assertion,
    message,
    context,
  }: let
  in
    addErrorContext
    "while ${context}"
    (assert assertMsgFunc {
      inherit name assertion message;
    }; true);

  /**
  Create a named test case with desired output, outcome expression, and an
  optional command string for display in test results.

  # Type
  ```nix
  mkTest :: { desired :: a, outcome :: a, command :: string? } -> Test
  ```

  # Examples
  ```nix
  mkTest {
    desired = "foo-bar";
    command = ''normalize "Foo Bar"'';
    outcome = normalize "Foo Bar";
  }
  ```
  */
  mkTest = {
    desired,
    outcome,
    command ? null,
  }:
    _build desired outcome command;

  /**
  Positional shorthand for `mkTest` - no command string.

  Useful in enum and validator test blocks where the expression is self-evident.

  # Type
  ```nix
  mkTest' :: a -> a -> Test
  ```

  # Examples
  ```nix
  validatesRust = mkTest' true  (languages.validator.check "rust")
  correctCount  = mkTest' 4     (length cpuBrands.values)
  ```
  */
  mkTest' = desired: outcome: _build desired outcome null;

  /**
  Create a test case that expects evaluation to throw.

  Uses `builtins.tryEval` to catch the error - the test passes only if
  evaluation fails.

  # Type
  ```nix
  mkThrows :: a -> Test
  ```

  # Examples
  ```nix
  mkThrows (validate { fnName = "f"; argName = "x"; desired = "set"; predicate = isAttrs; outcome = "oops"; })
  ```
  */
  mkThrows = outcome:
    mkTest {
      desired = {
        success = false;
        value = false;
      };
      outcome = tryEval outcome;
    };

  exports = {
    local = {
      inherit mkTest mkTest' mkThrows assertMsgFunc withContext;
    };
    alias = {
      inherit mkTest mkTest' mkThrows assertMsgFunc;
      assertWithContext = withContext;
    };
  };
in
  exports.local // {__rootAliases = exports.alias;}
