/**
Tests for `libraries/types/user/default.nix`.

Confirms every file in `libraries/types/user/` is exposed as
`lix.types.user.<fileName>`. See the host sibling for how to read a failure.
*/
args: harness: let
  inherit (harness) makeCase;
  userTypes = [
    "applications"
    "autoLogin"
    "capabilities"
    "description"
    "enable"
    "git"
    "hashedPassword"
    "interface"
    "localisation"
    "name"
    "packages"
    "paths"
    "role"
    "uid"
  ];
in
  map (
    typeName: makeCase "exposed" typeName (builtins.hasAttr typeName args.lix.types.user) true
  )
  userTypes
