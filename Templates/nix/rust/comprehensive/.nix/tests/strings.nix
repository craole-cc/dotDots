{
  lib,
  assertMsg,
}: let
  inherit
    (lib.strings)
    optionalString
    ensurePrefix
    ensureSuffix
    nonEmptyOrNull
    concatNonEmpty
    lines
    words
    ;
in {
  optionalStringTrue = assertMsg (
    optionalString true " enabled" == " enabled"
  ) "optionalString keeps the original string when enabled";

  optionalStringFalse = assertMsg (optionalString false " enabled" == "") "optionalString drops the string when disabled";

  ensurePrefix = assertMsg (
    ensurePrefix "/" "tmp/cache" == "/tmp/cache" && ensurePrefix "/" "/tmp/cache" == "/tmp/cache"
  ) "ensurePrefix prepends only when needed";

  ensureSuffix = assertMsg (
    ensureSuffix ".nix" "default" == "default.nix" && ensureSuffix ".nix" "default.nix" == "default.nix"
  ) "ensureSuffix appends only when needed";

  nonEmptyOrNull = assertMsg (
    nonEmptyOrNull null == null && nonEmptyOrNull "" == null && nonEmptyOrNull 42 == "42"
  ) "nonEmptyOrNull normalizes null and empty values";

  concatNonEmpty = assertMsg (
    concatNonEmpty "/" [
      "var"
      ""
      null
      "log"
    ]
    == "var/log"
  ) "concatNonEmpty joins only non-empty segments";

  lines = assertMsg (
    lines [
      "alpha"
      ""
      null
      "beta"
    ]
    == "alpha\nbeta"
  ) "lines joins non-empty segments with newlines";

  words = assertMsg (
    words [
      "cargo"
      ""
      null
      "test"
    ]
    == "cargo test"
  ) "words joins non-empty segments with spaces";
}
