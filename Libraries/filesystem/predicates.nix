{lib, ...}: let
  inherit (builtins) baseNameOf dirOf;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) elem;
  inherit (lib.trivial) pathExists;

  isNixFile = file: hasSuffix ".nix" (baseNameOf file);
  isExcludedFile = path: filesToExclude: elem (baseNameOf path) filesToExclude;
  isInExcludedFolder = path: foldersToExclude: elem (dirOf path) foldersToExclude;

  normalizeFlakePath = path: let
    strPath = toString path;
  in
    if hasSuffix "/flake.nix" strPath && pathExists strPath
    then dirOf strPath
    else if pathExists (strPath + "/flake.nix")
    then strPath
    else null;

  isFlakePath = path: (normalizeFlakePath path) != null;

  exports = {
    inherit
      isNixFile
      isExcludedFile
      isInExcludedFolder
      isFlakePath
      ;
  };
in
  exports // {_rootAliases = exports;}
