{ config, lib, ... }:
let
  mod = "types";

  #| External libraries
  inherit (builtins) baseNameOf match;
  inherit (lib) mkOption elem any;
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

  inherit (lib.types) path;

  #| Internal libraries
  inherit (config.DOTS) Libraries;
  inherit (Libraries.filesystem) locateProjectRoot pathOf;
in
with Libraries.${mod};
{
  options.DOTS.Libraries.${mod} = {

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

          absPath = pathOf path;
          absPatt = map (pattern: pathOf pattern) gitignorePatterns;

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
  };
}
