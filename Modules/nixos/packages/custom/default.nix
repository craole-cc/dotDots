{
  pkgs ? import <nixpkgs> { },
  paths ? null,
  ...
}:
{
  aider = pkgs.callPackage ./aider { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  dotDots = pkgs.callPackage ./dots { inherit paths; };
}
