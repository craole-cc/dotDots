{lib, ...}: let
  inherit (lib.packages) mkPkgs;
in {
  mkEditor = {
    name,
    suffix,
    templates,
    packages,
  }: {inherit name suffix templates packages;};
  mkGroups = {
    pkgs ? mkPkgs {},
    includeEditor ? false,
    ...
  }:
    if includeEditor
    then {
      editor = {
        packages = {inherit (pkgs) helix;};
      };
    }
    else {};
}
