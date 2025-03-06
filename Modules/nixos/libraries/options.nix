{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  # inherit (config.DOTS.lib.helpers) mkHash;

  inherit (config.DOTS.lib.filesystem)
    importNixModules
    importModules
    locateFlake
    locateGitRoot
    locateNixos
    locateParentByChild
    locateParentByChildren
    locateParentByName
    locateParentByNameOrChildren
    locateProjectRoot
    pathOrNull
    pathof
    pathofGitHub
    pathofPWD
    pathsIgnored
    pathsIgnoredCheck
    pathsIn
    ;
in
# with lib;
# with types;
# with config.DOTS.lib;
# with types;
# with config.DOTS.lib.filesystem;
with config.DOTS.lib.helpers;
{
  options.dib = {
    #| Helpers
    mkHash = mkOption { default = mkHash; };

    #| Filesystem
    # importNixModules = mkOption { default = importNixModules; };
    # listFilesRecursively = mkOption { default = listFilesRecursively; };
    # listNixModules = mkOption { default = listNixModules; };
    # locateParentByName = mkOption { default = locateParentByName; };
    # locateParentByNameOrChildren = mkOption { default = locateParentByNameOrChildren; };
    # locateParentByChildren = mkOption { default = locateParentByChildren; };
    # locateProjectRoot = mkOption { default = locateProjectRoot; };
    # pathof = mkOption { default = pathof; };

    #| Path
    # listNixModuleNames = mkOption { default = listNixModuleNames; };
    # listNixModulePaths = mkOption { default = listNixModulePaths; };
    # listNixModulesRecursively = mkOption { default = listNixModulesRecursively; };
    # nixModulesWithOptions = mkOption { default = nixModulesWithOptions; };
    # listNixPackagesRecursively = mkOption { default = listNixPackagesRecursively; };

    #| Types
    # inFileList = mkOption { default = inFileList; };
    # isAllowedDir = mkOption { default = isAllowedDir; };
    # isNixFile = mkOption { default = isNixFile; };
    # inFolderList = mkOption { default = inFolderList; };
    # isGitIgnored = mkOption { default = isGitIgnored; };
  };
}
