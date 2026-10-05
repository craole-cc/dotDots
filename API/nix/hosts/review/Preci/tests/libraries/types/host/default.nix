/**
Tests for `libraries/types/host/default.nix`.

Confirms every file in `libraries/types/host/` is exposed as
`lix.types.host.<fileName>`. A failure means either the file is not wired into
`default.nix` or it is exposed under a different name; decide which, then fix
the code or this list. The per-file behaviour is tested in the sibling files.
*/
args: harness: let
  inherit (harness) makeCase;
  inherit (args.lix.attrsets) hasAttr;
  inherit (args.lix.types) host;
in
  map (
    typeName:
      makeCase "exposed" typeName (hasAttr typeName host) true
  )
  [
    "applications"
    "class"
    "cpu"
    "description"
    "functionalities"
    "id"
    "interface"
    "kernel"
    "localisation"
    "name"
    "packages"
    "paths"
    "principals"
    "specs"
    "stateVersion"
    "system"
    "type"
    "mkHost"
  ]
