{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.paths) flakeOrNull;
  inherit (_.debug.assertions) mkTest mkTest';
  inherit (_.debug.runners) runTests;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) elem;

  exports = rec {
    internal = {
      inherit
        isExcludedFile
        isFlakePath
        isInExcludedFolder
        isNixFile
        isPath
        isStorePath
        pathExists
        ;
    };
    external = internal;
  };

  /**
  Check whether a value is a valid path.

  Returns `true` if the specified file system `path` exists during Nix
  evaluation time, and `false` otherwise.

  Useful for conditionally importing local files, verifying data directories,
  or setting fallback configurations.

  **Note:** Checks path at *evaluation* time, so the path must be accessible
  to the Nix evaluator.

  **Example:**
  ```nix
  let
    localSettings = if pathExists ./local-config.nix
                    then import ./local-config.nix
                    else {};
  in
    { environment.systemPackages = [ pkgs.hello ]; } // localSettings
  */
  pathExists = path: builtins.pathExists path;

  /**
  Check whether a value is a path.

  # Type
  ```nix
  isPath :: any -> bool
  ```

  # Examples
  ```nix
  isPath /etc/hosts  # => true
  isPath "/etc"      # => false (string, not path)
  ```
  */
  isPath = path: lib.strings.isPath path;

  /**
  Check whether a value is a valid Nix store path.

  # Type
  ```nix
  isStorePath :: any -> bool
  ```

  # Examples
  ```nix
  isStorePath "/nix/store/abc123-foo"  # => true
  isStorePath "/etc/hosts"             # => false
  ```
  */
  isStorePath = lib.strings.isStorePath;

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
  Check whether a path is a valid flake root.

  # Type
  ```nix
  isFlakePath :: path | string -> bool
  ```
  */
  isFlakePath = path: (flakeOrNull path) != null;
in
  exports.internal
  // {
    _rootAliases = exports.external;
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

      flakePath = {
        rejectsNonExistentPath = mkTest {
          desired = null;
          outcome = flakeOrNull "/this/path/does/not/exist/at/all";
          command = ''flakePath "/this/path/does/not/exist/at/all"'';
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
