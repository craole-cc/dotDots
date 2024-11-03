{ config, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (config.DOTS) Libraries;
in
# with lib;
# with types;
with config.DOTS.Libraries;
with types;
with filesystem;
with path;
{
  options.dib = {

    #| Filesystem
    importNixModules = mkOption { default = importNixModules; };
    listFilesRecursively = mkOption { default = listFilesRecursively; };
    listNixModules = mkOption { default = listNixModules; };
    locateParentByName = mkOption { default = locateParentByName; };
    locateParentByNameOrChildren = mkOption { default = locateParentByNameOrChildren; };
    locateParentByChildren = mkOption { default = locateParentByChildren; };
    locateProjectRoot = mkOption { default = locateProjectRoot; };
    pathOf = mkOption { default = pathOf; };

    #| Path
    # listNixModuleNames = mkOption { default = listNixModuleNames; };
    # listNixModulePaths = mkOption { default = listNixModulePaths; };
    # listNixModulesRecursively = mkOption { default = listNixModulesRecursively; };
    # nixModulesWithOptions = mkOption { default = nixModulesWithOptions; };
    listNixPackagesRecursively = mkOption { default = listNixPackagesRecursively; };

    #| Types
    inFileList = mkOption { default = inFileList; };
    isAllowedDir = mkOption { default = isAllowedDir; };
    isNixFile = mkOption { default = isNixFile; };
    inFolderList = mkOption { default = inFolderList; };
    isGitIgnored = mkOption { default = isGitIgnored; };
  };
}
