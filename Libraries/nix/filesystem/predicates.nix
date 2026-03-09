{
  _,
  lib,
  ...
}: let
  inherit (_.types.predicates) isString;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) elem;
  inherit (lib.trivial) pathExists;

  /**
  Check whether a path refers to a `.nix` file.

  # Type
  ```nix
  isNixFile :: path | string -> bool
  ```
  */
  isNixFile = file: hasSuffix ".nix" (baseNameOf file);

  /**
  Check whether the basename of a path is in an exclusion list.

  # Type
  ```nix
  isExcludedFile :: path | string -> [string] -> bool
  ```
  */
  isExcludedFile = path: filesToExclude: elem (baseNameOf path) filesToExclude;

  /**
  Check whether the immediate parent directory of a path is in an exclusion list.

  # Type
  ```nix
  isInExcludedFolder :: path | string -> [string] -> bool
  ```
  */
  isInExcludedFolder = path: foldersToExclude: elem (dirOf path) foldersToExclude;

  /**
  Normalize a flake path. Accepts a `flake.nix` file or a directory
  containing one. Returns the directory string, or null if not found.

  # Type
  ```nix
  normalizeFlakePath :: path | string -> string | null
  ```
  */
  normalizeFlakePath = path: let
    strPath = toString path;
  in
    if !isString strPath
    then null
    else if hasSuffix "/flake.nix" strPath && pathExists strPath
    then dirOf strPath
    else if pathExists (strPath + "/flake.nix")
    then strPath
    else null;

  /**
  Check whether a path is a valid flake root.

  # Type
  ```nix
  isFlakePath :: path | string -> bool
  ```
  */
  isFlakePath = path: (normalizeFlakePath path) != null;

  exports = {
    inherit isNixFile isExcludedFile isInExcludedFolder isFlakePath normalizeFlakePath;
  };
in
  exports
  // {
    _rootAliases = exports;

    _tests = runTests {
      isNixFile = {
        detectsNixExtension = mkTest' true (isNixFile "/foo/bar.nix");
        rejectsNonNix = mkTest' false (isNixFile "/foo/bar.txt");
        rejectsNoExtension = mkTest' false (isNixFile "/foo/bar");
      };

      isExcludedFile = {
        detectsExcluded = mkTest {
          desired = true;
          outcome = isExcludedFile "/foo/default.nix" ["default.nix" "flake.nix"];
          command = ''isExcludedFile "/foo/default.nix" ["default.nix" "flake.nix"]'';
        };
        allowsNonExcluded = mkTest {
          desired = false;
          outcome = isExcludedFile "/foo/bar.nix" ["default.nix" "flake.nix"];
          command = ''isExcludedFile "/foo/bar.nix" ["default.nix" "flake.nix"]'';
        };
        emptyList = mkTest {
          desired = false;
          outcome = isExcludedFile "/foo/default.nix" [];
          command = ''isExcludedFile "/foo/default.nix" []'';
        };
      };

      isInExcludedFolder = {
        detectsExcludedParent = mkTest {
          desired = true;
          outcome = isInExcludedFolder "/foo/review/bar.nix" ["review" "tmp"];
          command = ''isInExcludedFolder "/foo/review/bar.nix" ["review" "tmp"]'';
        };
        allowsNonExcludedParent = mkTest {
          desired = false;
          outcome = isInExcludedFolder "/foo/src/bar.nix" ["review" "tmp"];
          command = ''isInExcludedFolder "/foo/src/bar.nix" ["review" "tmp"]'';
        };
      };

      normalizeFlakePath = {
        rejectsNonExistentPath = mkTest {
          desired = null;
          outcome = normalizeFlakePath "/this/path/does/not/exist/at/all";
          command = ''normalizeFlakePath "/this/path/does/not/exist/at/all"'';
        };
      };

      isFlakePath = {
        rejectsNonExistentPath = mkTest {
          desired = false;
          outcome = isFlakePath "/this/path/does/not/exist/at/all";
          command = ''isFlakePath "/this/path/does/not/exist/at/all"'';
        };
      };
    };
  }
