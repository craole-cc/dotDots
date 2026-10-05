/**
Tests for `libraries/functions/trivial.nix`.
*/
args: harness: let
  inherit (harness) makeCase;
  lix = args.lix;
  inherit (lix.strings) typeOf;
in [
  (makeCase "typeOf" "agrees with strings.typeOf" (typeOf null) (typeOf null))
]
