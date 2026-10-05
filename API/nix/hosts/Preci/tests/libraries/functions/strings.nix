/**
Tests for `libraries/functions/strings.nix`.

Argument order is (needle, haystack), as in nixpkgs. A failure means lix differs
from nixpkgs, which affects every caller written against nixpkgs semantics.
*/
args: harness: let
  inherit (harness) makeCase;
  lix = args.lix;
  inherit (lix.strings) concatStringsSep fromJSON hasInfix hasPrefix hasSuffix isString match removePrefix splitString toLower;
in [
  (makeCase "hasPrefix" "hit" (hasPrefix "ab" "abc") true)
  (makeCase "hasPrefix" "miss" (hasPrefix "bc" "abc") false)
  (makeCase "hasInfix" "hit" (hasInfix "b" "abc") true)
  (makeCase "hasInfix" "miss" (hasInfix "x" "abc") false)
  (makeCase "hasSuffix" "hit" (hasSuffix "bc" "abc") true)
  (makeCase "hasSuffix" "miss" (hasSuffix "ab" "abc") false)
  (makeCase "removePrefix" "hit" (removePrefix "ab" "abc") "c")
  (makeCase "removePrefix" "miss leaves string alone" (removePrefix "x" "abc") "abc")
  (makeCase "splitString" "basic" (splitString "_" "a_b_c") ["a" "b" "c"])
  (makeCase "splitString" "splits inside x86_64 (why cpu.nix peels the arch first)" (splitString "_" "x86_64") ["x86" "64"])
  (makeCase "splitString" "leading separator yields empty first part" (splitString "_" "_a") ["" "a"])
  (makeCase "concatStringsSep" "concatStringsSep" (concatStringsSep "-" ["a" "b"]) "a-b")
  (makeCase "toLower" "toLower" (toLower "CachyOS") "cachyos")
  (makeCase "isString" "yes" (isString "x") true)
  (makeCase "isString" "no" (isString 1) false)
  (makeCase "fromJSON" "number" (fromJSON "25") 25)
  (makeCase "match" "digits hit" (match "[0-9]+" "25" != null) true)
  (makeCase "match" "digits miss" (match "[0-9]+" "ab") null)
  (makeCase "typeOf" "int" (lix.strings.typeOf 1) "int")
  (makeCase "typeOf" "string" (lix.strings.typeOf "a") "string")
  (makeCase "typeOf" "list" (lix.strings.typeOf []) "list")
  (makeCase "typeOf" "attrset" (lix.strings.typeOf {}) "set")
]
