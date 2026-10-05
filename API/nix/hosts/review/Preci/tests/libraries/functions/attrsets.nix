/**
Tests for `libraries/functions/attrsets.nix`, following nixpkgs conventions.
*/
args: harness: let
  inherit (harness) makeCase;
  inherit (args.lix.attrsets) filterAttrs isAttrs recursiveUpdate;
in [
  (
    makeCase "isAttrs" "attrset" (isAttrs {}) true
  )
  (
    makeCase "isAttrs" "list" (isAttrs []) false
  )
  (
    makeCase "isAttrs" "null" (isAttrs null) false
  )
  (
    makeCase "recursiveUpdate" "merges nested" (recursiveUpdate {
      outer = {
        kept = 1;
        changed = 2;
      };
    } {outer = {changed = 3;};}) {
      outer = {
        kept = 1;
        changed = 3;
      };
    }
  )
  (
    makeCase "recursiveUpdate" "replaces lists" (recursiveUpdate {items = [1];} {items = [2];}) {items = [2];}
  )
  (
    makeCase "filterAttrs" "filterAttrs" (filterAttrs (attrName: attrValue: attrValue != null) {
      kept = 1;
      dropped = null;
    }) {kept = 1;}
  )
]
