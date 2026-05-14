/**
  libraries/filesystem/paths.nix

  Path-discovery helpers for lib.filesystem.
*/
{ lib }:
let
  inherit (lib.filesystem) pathIsRegularFile pathType readDir;
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists)
    concatMap
    elem
    filter
    flatten
    isList
    map
    ;
  inherit (lib.strings) hasSuffix;

  /**
    Directory names that are skipped during library discovery.

    # Type
    ```nix
    foldersToExclude :: [string]
    ```

    # Examples
    ```nix
    foldersToExclude
    # => [ "archives" "review" "temp" "tmp" ]
    ```

    # Returns
    A list of directory names skipped by default during path discovery.
  */
  foldersToExclude = [
    "archives"
    "review"
    "temp"
    "tmp"
  ];

  /**
    Return whether a directory entry is a non-default `.nix` file.

    # Type
    ```nix
    isNixFile :: string -> string -> bool
    ```

    # Examples
    ```nix
    isNixFile "core.nix" "regular"
    # => true

    isNixFile "default.nix" "regular"
    # => false
    ```

    # Returns
    `true` only for regular `.nix` files other than `default.nix`.
  */
  isNixFile = name: entry: entry == "regular" && hasSuffix ".nix" name && name != "default.nix";

  /**
    Return whether a directory entry is a traversable subdirectory.

    Built-in excluded folder names from `foldersToExclude` are always skipped.

    # Type
    ```nix
    isIncludedDir :: string -> string -> bool
    ```

    # Examples
    ```nix
    isIncludedDir "modules" "directory"
    # => true

    isIncludedDir "tmp" "directory"
    # => false
    ```

    # Returns
    `true` when the entry is a directory and is not in `foldersToExclude`.
  */
  isIncludedDir = name: entry: entry == "directory" && !(elem name foldersToExclude);

  /**
    Collect importable Nix paths from a directory.

    Directories containing `default.nix` are returned as directory paths so they
    can be imported as a unit. When `recurse` is enabled, nested directories
    without `default.nix` are traversed. `ignore` filters entries by basename.

    # Type
    ```nix
    collectFromDir :: {
      path :: path;
      recurse ? bool;
      ignore ? [string];
    } -> [path]
    ```

    # Examples
    ```nix
    collectFromDir {
      path = ./tests/fixtures/filesystem/plain;
    }
    # => [
    #   ./tests/fixtures/filesystem/plain/a.nix
    #   ./tests/fixtures/filesystem/plain/z.nix
    # ]

    collectFromDir {
      path = ./tests/fixtures/filesystem/nested;
      recurse = true;
      ignore = ["deep"];
    }
    # => [
    #   ./tests/fixtures/filesystem/nested/root.nix
    #   ./tests/fixtures/filesystem/nested/has-default
    # ]
    ```

    # Returns
    A list of importable file and directory paths discovered under `path`.
  */
  collectFromDir =
    {
      path,
      recurse ? false,
      ignore ? [ ],
    }:
    let
      entries = readDir path;

      filePaths = map (name: path + "/${name}") (
        filter (name: !(elem name ignore) && isNixFile name entries.${name}) (attrNames entries)
      );

      dirPaths = concatMap (
        name:
        let
          subPath = path + "/${name}";
          subEntries = readDir subPath;
          hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
        in
        if hasDefault then
          [ subPath ]
        else if recurse then
          collectFromDir {
            path = subPath;
            inherit recurse;
            inherit ignore;
          }
        else
          [ ]
      ) (filter (name: !(elem name ignore) && isIncludedDir name entries.${name}) (attrNames entries));
    in
    filePaths ++ dirPaths;

  /**
    Collect importable Nix paths from one path or a list of paths.

    Directories delegate to `collectFromDir`; regular `.nix` files are returned
    as-is. Non-Nix files are ignored.

    # Type
    ```nix
    collectPaths :: {
      path :: path | [path];
      recurse ? bool;
      ignore ? [string];
    } -> [path]
    ```

    # Examples
    ```nix
    collectPaths {
      path = ./tests/fixtures/filesystem/plain/a.nix;
    }
    # => [ ./tests/fixtures/filesystem/plain/a.nix ]

    collectPaths {
      path = [
        ./tests/fixtures/filesystem/plain/a.nix
        ./tests/fixtures/filesystem/plain/z.nix
      ];
    }
    # => [
    #   ./tests/fixtures/filesystem/plain/a.nix
    #   ./tests/fixtures/filesystem/plain/z.nix
    # ]
    ```

    # Returns
    A flattened list of importable Nix paths from the provided path input.
  */
  collectPaths =
    {
      path,
      recurse ? false,
      ignore ? [ ],
    }:
    flatten (
      map (
        p:
        if pathType p == "directory" then
          collectFromDir {
            path = p;
            inherit recurse;
            inherit ignore;
          }
        else if pathIsRegularFile p && !(elem (baseNameOf p) ignore) && hasSuffix ".nix" (baseNameOf p) then
          [ p ]
        else
          [ ]
      ) (if isList path then path else [ path ])
    );
in
{
  inherit
    foldersToExclude
    isNixFile
    isIncludedDir
    collectFromDir
    collectPaths
    ;
}
