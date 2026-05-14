{ lib, assertMsg }:
let
  inherit (lib.attrsets)
    optionalAttr
    recursiveAttrs
    compactAttrs
    mapFilterAttrs
    toEnv
    ;
in
{
  optionalAttrTrue = assertMsg ((optionalAttr true "foo" 42) == { foo = 42; }) "optionalAttr true";

  optionalAttrFalse = assertMsg ((optionalAttr false "foo" 42) == { }) "optionalAttr false";

  optionalAttrDynamicName = assertMsg (
    (optionalAttr true "feature-flag" false) == { "feature-flag" = false; }
  ) "optionalAttr preserves dynamic attribute names and values";

  recursiveAttrs = assertMsg (
    (recursiveAttrs {
      a = {
        b = 1;
      };
      c = {
        b = 2;
        d = {
          e = 3;
        };
      };
    }) == {
      a.b = 1;
      c.b = 2;
      c.d.e = 3;
    }
  ) "recursiveAttrs merges";

  recursiveAttrsEmpty = assertMsg (recursiveAttrs { } == { }) "recursiveAttrs handles an empty attrset";

  compactAttrs = assertMsg (
    (compactAttrs {
      a = 1;
      b = null;
      enabled = false;
      c = "";
    }) == {
      a = 1;
      enabled = false;
      c = "";
    }
  ) "compactAttrs removes null";

  mapFilterAttrs = assertMsg (
    (mapFilterAttrs (n: v: if v == null then null else "${n}_x${toString v}") {
      a = 1;
      b = null;
      c = 2;
    }) == {
      a = "a_x1";
      c = "c_x2";
    }
  ) "mapFilterAttrs compacts";

  toEnv = assertMsg (
    (toEnv {
      VERSION = 1;
      DEBUG = true;
      NULL = null;
    }) == {
      VERSION = "1";
      DEBUG = "true";
    }
  ) "toEnv stringifies/compacts";
}
