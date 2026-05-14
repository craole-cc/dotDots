{
  lib ? (import <nixpkgs> { }).lib,
}:
let
  inherit (lib.asserts) assertMsg;
  inherit (lib.attrsets) attrNames mapAttrs;
  inherit (lib.lists) foldl' length;

  namespaces = {
    attrsets = import ./attrsets.nix { inherit lib assertMsg; };
    filesystem = import ./filesystem.nix { inherit lib assertMsg; };
    strings = import ./strings.nix { inherit lib assertMsg; };
  };
  names = attrNames namespaces;
in
{
  ok = true;
  namespaceCount = length names;
  testCount = foldl' (acc: name: acc + length (attrNames namespaces.${name})) 0 names;

  tests = mapAttrs (name: suite: {
    count = length (attrNames suite);
    names = attrNames suite;
  }) namespaces;
}
