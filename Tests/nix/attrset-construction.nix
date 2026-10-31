{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.attrsets.construction) asAttrs optionalAttr;
  tests = {
    testNamedPositional = {
      expr = asAttrs [true "port" 8080];
      expected.port = 8080;
    };
    testDefaultPositionalValue = {
      expr = asAttrs [true "enabled"];
      expected.enabled = true;
    };
    testFalsePositional = {
      expr = asAttrs [false "port" (throw "Disabled values must stay lazy")];
      expected = {};
    };
    testNullValue = {
      expr = optionalAttr true "port" null;
      expected = {};
    };
    testEmptyListCondition = {
      expr = optionalAttr [] "after" [];
      expected.after = [];
    };
    testKeywordAttributes = {
      expr = asAttrs {
        __name = "service";
        port = 8080;
      };
      expected.service.port = 8080;
    };
  };
in {
  total = lix.lists.access.length (lix.attrsets.access.attrNames tests);
  failures = lib.runTests tests;
}
