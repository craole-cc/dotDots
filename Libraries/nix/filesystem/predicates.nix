{lib, ...}: let
  inherit (builtins) baseNameOf dirOf;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) elem;

  isNixFile = file: hasSuffix ".nix" (baseNameOf file);
  isExcludedFile = path: filesToExclude: elem (baseNameOf path) filesToExclude;
  isInExcludedFolder = path: foldersToExclude: elem (dirOf path) foldersToExclude;
in {
  inherit
    isNixFile
    isExcludedFile
    isInExcludedFolder
    ;
}
