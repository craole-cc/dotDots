/**
Tests for `libraries/functions/lists.nix`, following nixpkgs conventions.
*/
args: harness: let
  inherit (harness) makeCase;
  lix = args.lix;
  inherit (lix.lists) all elem filter findFirst findFirstIndex head length optional range take;
in [
  (makeCase "elem" "hit" (elem 1 [1 2]) true)
  (makeCase "elem" "miss" (elem 3 [1 2]) false)
  (makeCase "filter" "filter" (filter (number: number > 1) [1 2 3]) [2 3])
  (makeCase "findFirst" "hit" (findFirst (number: number > 1) null [1 2 3]) 2)
  (makeCase "findFirst" "miss gives default" (findFirst (number: number > 5) null [1 2]) null)
  (makeCase "findFirstIndex" "hit" (findFirstIndex (number: number > 1) null [1 2 3]) 1)
  # kernel.nix relies on the default being returned untouched.
  (makeCase "findFirstIndex" "miss gives default" (findFirstIndex (number: number > 5) 99 [1 2]) 99)
  (makeCase "take" "fewer" (take 2 [1 2 3]) [1 2])
  (makeCase "take" "more than available" (take 5 [1 2]) [1 2])
  (makeCase "range" "range" (range 2 4) [2 3 4])
  (makeCase "range" "empty when reversed" (range 5 4) [])
  (makeCase "head" "head" (head [1 2]) 1)
  (makeCase "length" "length" (length [1 2 3]) 3)
  (makeCase "all" "true" (all (number: number > 0) [1 2]) true)
  (makeCase "all" "false" (all (number: number > 1) [1 2]) false)
  (makeCase "all" "of nothing is true" (all (number: number > 1) []) true)
  (makeCase "optional" "true" (optional true "a") ["a"])
  (makeCase "optional" "false" (optional false "a") [])
]
