/**
Tests for `libraries/functions/debug.nix`.

The harness is built on `tryEval` and `deepSeq`, so these are the first
things to check if every suite starts failing at once.
*/
args: harness: let
  inherit (harness) makeCase;
  lix = args.lix;
  inherit (lix.debug) deepSeq tryEval;
in [
  (makeCase "tryEval" "success" (tryEval 1) {success = true; value = 1;})
  (makeCase "tryEval" "catches throw" (tryEval (throw "boom")).success false)
  (makeCase "tryEval" "deepSeq reaches inside lists" (tryEval (deepSeq [(throw "boom")] 1)).success false)
]
