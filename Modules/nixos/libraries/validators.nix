{
  config,
  lib,
  ...
}:
let
  #| Module Parts
  top = "DOTS";
  dom = "lib";
  mod = "types";
  alt = "dib";

  #| Imports
  inherit (builtins) baseNameOf match;
  inherit (lib) mkOption elem any;
  inherit (lib.filesystem) pathIsDirectory;
  inherit (lib.strings)
    # stringToCharacters
    # hasPrefix
    hasSuffix
    hasInfix
    splitString
    # removeSuffix
    # normalizePath
    fileContents
    replaceStrings
    ;

  #| Module Imports
  inherit (config.DOTS.lib.filesystem) locateProjectRoot pathof;

  #| Module Options
  isNixFile = mkOption {
    description = "Check if a file is a Nix file";
    example = ''isNixFile "file.nix"'';
    default = file: hasSuffix ".nix" (baseNameOf file);
  };

  isAllowedDir = mkOption {
    description = "Check if a file is a Nix file.";
    example = ''isNixFile "file.nix"'';
    default =
      path:
      let
        isDir = pathIsDirectory path;
        isAllowed = !isGitIgnored path;
      in
      isDir && isAllowed;
  };

  inFileList = mkOption {
    description = "Check if a file is excluded based on a list of files to exclude.";
    example = ''isExcludedFile "file.txt"'';
    default = _file: _files: elem (baseNameOf _file) _files;
  };

  inFolderList = mkOption {
    description = "Check if a file is in an excluded folder based on a list of folders to exclude.";
    example = ''isExcludedFolder "/path/to/folder"'';
    default = _folder: _folders: any (pattern: hasInfix pattern _folder) _folders;
  };

  isGitIgnored = mkOption {
    description = "Check if a file is ignored by Git based on entries in .gitignore.";
    example = ''isGitIgnored "file.txt"'';
    default =
      path:
      let
        gitignorePath = locateProjectRoot + "/.gitignore";
        gitignoreContents = fileContents gitignorePath;
        gitignorePatterns = splitString "\n" gitignoreContents;

        absPath = pathof path;
        absPatt = map (pattern: pathof pattern) gitignorePatterns;

        matchesPattern =
          pattern: file:
          let
            regex = replaceStrings [ "*" ] [ ".*" ] pattern;
          in
          match regex file != null;

        matches = any (pattern: matchesPattern pattern absPath) absPatt;
      in
      matches;
  };

  #| Module Exports
  exports = {
    inherit
      isNixFile
      isAllowedDir
      inFileList
      inFolderList
      isGitIgnored
      ;
  };
in
{
  options = {
    ${top}.${dom}.${mod} = exports;
    ${alt} = exports;
  };
}
