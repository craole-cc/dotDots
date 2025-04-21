{
  pkgs ? import <nixpkgs> {},
  paths ? null,
  ...
}: {
  aider = pkgs.callPackage ./aider {};
  lyrics = pkgs.python3Packages.callPackage ./lyrics {};
  dotshell = pkgs.callPackage ./dots {inherit paths;};
}
