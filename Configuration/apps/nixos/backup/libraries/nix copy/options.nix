{ config, lib, ... }:
with lib;
with types;
with config.dot.lib;
{
  options.dot.dib = {

    #| Filesystem
    importNixModules = mkOption { default = filesystem.importNixModules; };
    listDirectories = mkOption { default = filesystem.listDirectories; };
    listNixModuleNames = mkOption { default = filesystem.listNixModuleNames; };
    listNixModulePaths = mkOption { default = filesystem.listNixModulePaths; };
    listNixModules = mkOption { default = filesystem.listNixModules; };
    listNixModulesRecursively = mkOption { default = filesystem.listNixModulesRecursively; };
    locateParentByName = mkOption { default = filesystem.locateParentByName; };
    locateParentByNameOrChildren = mkOption { default = filesystem.locateParentByNameOrChildren; };
    locateParentByChildren = mkOption { default = filesystem.locateParentByChildren; };
    locateProjectRoot = mkOption { default = filesystem.locateProjectRoot; };
    nixModulesWithOptions = mkOption { default = filesystem.nixModulesWithOptions; };
    pathOf = mkOption { default = filesystem.pathOf; };

    #| Types
    inFileList = mkOption { default = types.inFileList; };
    isAllowedDir = mkOption { default = types.isAllowedDir; };
    isNixFile = mkOption { default = types.isNixFile; };
    inFolderList = mkOption { default = types.inFolderList; };
    isGitIgnored = mkOption { default = types.isGitIgnored; };
  };
}
