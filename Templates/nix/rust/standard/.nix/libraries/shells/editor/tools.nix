{lib, ...}: let
  inherit (lib.packages) mkPkgs;
in {
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
