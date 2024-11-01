{
  lib,
  dib,
  ...
}:
let
  inherit (builtins)
    baseNameOf
    tryEval
    getEnv
    pathExists
    ;
  inherit (lib)
    any
    elem
    filter
    # head
    length
    ;
  inherit (lib.lists)
    toList
    foldl'
    head
    tail
    ;
  inherit (lib.strings)
    stringToCharacters
    hasPrefix
    hasSuffix
    splitString
    removeSuffix
    fileContents
    ;
  inherit (lib.attrsets) nameValuePair listToAttrs;
  inherit (lib.filesystem) locateDominatingFile listFilesRecursive;
  inherit (lib.options) mkOption;
  inherit (dib.lists)
    prep
    clean
    infixed
    suffixed
    ;
in
with dib.filesystem;
{
  /**
    "Get the current working directory."
  */
  PWD = getEnv "PWD";

  /**
    pathOf :: path -> absolute path

    "Obtains the absolute path of a given file or directory, relative to the project root."

    Parameters:
      _path = Path to convert to an absolute path.

    Returns: absolute path

    Example:
      pathOf "src/configurations/user/review/craole.bac.nix"
      => "/etc/nixos/src/configurations/user/review/craole.bac.nix"
  */
  pathOf =
    _path:
    foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x + y) "" (
      stringToCharacters (toString _path)
    );

  pathOrNull = _path: if pathExists (pathOf _path) then pathOf _path else null;

  # "Recursively list path items including directories, files and modules
  pathsIn =
    let
      #| Validation
      isInDir = _path: _directory: dirOf _path == _directory;
      isNixModule = _file: hasSuffix ".nix" _file;
      isNixSpecial =
        _file:
        any (suffix: hasSuffix suffix _file) [
          "default.nix"
          "flake.nix"
          "flake.lock"
          "shell.nix"
          "package.nix"
          "options.nix"
          "config.nix"
          "modules.nix"
          "module.nix"
        ];

      #| Filters
      # modulesBase = { base, list }: filter (p: (dirOf p == base)) list;
      # modulesNix =
      #   fileList:
      #   (suffixed {
      #     list = fileList;
      #     target = "nix";
      #   }).filtered;
      # modulesNixSpecial =
      #   list:
      #   (suffixed {
      #     inherit list;
      #     target = [
      #       "default.nix"
      #       "flake.nix"
      #       "flake.lock"
      #       "shell.nix"
      #       "package.nix"
      #       "options.nix"
      #       "config.nix"
      #       "modules.nix"
      #       "module.nix"
      #     ];
      #   }).inverted;

      #| Utility
      trimNix = _file: removeSuffix ".nix" _file;
    in
    _path:
    let
      path' = pathOf _path;
      paths = listFilesRecursive path';
      isBaseModule = _path: isInDir _path path';

      #| Lists
      lists = rec {
        all = prep (filter (_p: _p != path') (paths ++ map (_p: dirOf _p) paths));
        perDots = pathsIgnored.perDots all;
        perNix = rec {
          base = filter (_p: isBaseModule _p && isNixModule _p && !isNixSpecial _p) perDots;
          sub = {
            dir = map (_p: dirOf _p) (
              filter (_p: !isBaseModule _p && isNixModule _p && isNixSpecial _p) perDots
            );
            file = filter (
              _p: !isBaseModule _p && !isNixSpecial _p && !elem _p sub.dir && (!elem (dirOf _p) sub.dir)
            ) perDots;
          };
          paths = base ++ sub.dir ++ sub.file;
          names = map (_p: trimNix _p) (map (_p: baseNameOf _p) paths);
        };
      };

      #| Sets
      attrs = {
        all = listToAttrs (map (_p: nameValuePair (baseNameOf _p) _p) lists.all);
        perDots = listToAttrs (map (_p: nameValuePair (baseNameOf _p) _p) lists.perDots);
        perNix = listToAttrs (map (_p: nameValuePair (trimNix (baseNameOf _p)) _p) lists.perNix.paths);
      };
    in
    {
      inherit lists attrs;
      # inherit (lists) perNix;

      all = {
        lists = lists.all;
        attrs = attrs.all;
      };

      perDots = {
        lists = lists.perDots;
        attrs = attrs.perDots;
      };

      perNix = {
        lists = {
          inherit (lists.perNix)
            base
            sub
            paths
            names
            ;
        };
        attrs = attrs.perNix;
      };

    };
  pathsIgnored =
    let
      check =
        pathList: ignoreList:
        clean
          (suffixed {
            list =
              (infixed {
                list = pathList;
                target = map (_p: "/" + _p + "/") ignoreList;
              }).inverted;
            target = map (_p: "/" + _p) ignoreList;
          }).inverted;
    in
    {
      perDots =
        let
          toIgnore = [
            #| Settings
            ".env"
            ".envrc"
            ".git"
            ".github"
            ".gitlab"
            ".gitignore"
            ".vscode"
            ".sops.yaml"
            ".ignore"

            #| Project
            "LICENSE"
            "README"
            "bin"

            #| Nix
            # "default.nix"
            # "flake.nix"
            # "flake.lock"
            # "shell.nix"
            # "package.nix"
            # "options.nix"
            # "config.nix"
            # "modules.nix"
            # "module.nix"
            "settings"

            #| Temporary
            "review"
            "tmp"
            "temp"
            "result"
            ".Trash-1000"
            ".DS_Store"
            "archive"
          ];
        in
        _pathList: check _pathList toIgnore;
      # mkOption {
      #   description = "Process ignore checks based on the .dotignore file at the project root";
      #   default = _pathList: check _pathList toIgnore;
      # };

      perGit =
        let
          toIgnore = splitString "\n" (fileContents (locateProjectRoot + "/.gitignore")) ++ [
            ".git"
            ".gitignore"
          ];
        in
        _pathList: check _pathList toIgnore;
      # mkOption {
      #   description = "Process ignore checks based on the .dotignore file at the project root";
      #   default = _pathList: check _pathList toIgnore;
      # };
    };

  importModules = mkOption {
    description = "List all nix paths in a directory.";
    example = ''nixModulesToImport "path/to/directory"'';
    default =
      _path:
      let
        modules = (pathsIn _path).perNix.list.paths;
      in
      map (_module: import _module) modules;
  };

  /**
    Find the absolute path of the first parent directory of an item or a list of children.

    Parameters:
      _child = Child to search.

    Returns: absolute path

    Example:
      locateParentByChild "src" ==> "/path/to/project"
  */
  locateParentByChild =
    _child:
    let
      _starting_directory = (getEnv "PWD");
      result = locateDominatingFile _child _starting_directory;
      nullOrLocation = if result != null then builtins.toString result.path else null;
    in
    nullOrLocation;

  /**
    Find the absolute path of the first parent directory of an item or a list of children.

    Parameters:
      _children = List of children to search.

    Returns: absolute path

    Example:
      locateParentByChildren "src" ==> "/path/to/project"
  */
  # locateParentByChildren =
  #   {
  #     children,
  #     workingDir ? (getEnv "PWD"),
  #   }:
  #   let
  #     # search = child: locateDominatingFile child workingDir;
  #     search = _child: locateParentByChild _child;
  #     result = filter (_p: _p != null) (map search (toList children));
  #     nullOrLocation = if length result > 0 then (head result) else null;
  #   in
  #   head result;

  /**
    Find the absolute path of a specific path (by name) in a parent directory.

    Parameters:
      _name = Name of the parent directory to search.

    Returns: absolute path

    Example:
      locateParentByName "src" ==> "/path/to/project/src"
  */
  locateParentByName =
    _name:
    let
      result = locateParentByChildren _name;
      nullOrLocation = if result != null then result + "/${_name}" else null;
    in
    nullOrLocation;

  /**
    Find the absolute path of a parent directory by name, falling back to files or a list of files for search.

    Parameters:
      _name = Name of the parent directory to search.
      _children = List of files to search for.

    Returns: absolute path

    Example:
      locateParentByNameOrChildren "src" [".git" ".gitignore" ".flake.nix"] ==> "/path/to/project/root"
  */
  locateParentByNameOrChildren =
    _name: _children:
    let
      byName = locateParentByName _name;
      byChildren = locateParentByChildren _children;
      nullOrLocation = if byName != null then byName else byChildren;
    in
    nullOrLocation;

  /**
    "Find the absolute path of the project root."

    Parameters:
      _path = Path to convert to an absolute path.

    Returns: absolute path

    Example:
      locateProjectRoot ==> "/path/to/project/root"
  */
  # locateProjectRoot = locateParentByChildren {
  #   children = [
  #     "flake.nix"
  #     "flake.lock"
  #     "Cargo.lock"
  #     "Cargo.toml"
  #     ".git"
  #     ".gitignore"
  #     ".envrc"
  #     ".cargo.lock"
  #     "package.json"
  #   ];
  # };
  locateProjectRoot = locateFlakeRoot;

  locateFlakeRoot = locateParentByChild "flake.nix";

  # Helper function to locate a single file
  locateParentByChild' =
    {
      child,
      workingDir ? (getEnv "PWD"),
    }:
    let
      # Start from working directory and walk up until root
      findUp =
        dir:
        let
          filePath = dir + "/${child}";
          parentDir = dirOf dir;
        in
        if pathExists filePath then
          dir # Found the file, return current directory
        else if
          dir == parentDir # Reached root
        then
          null
        else
          findUp parentDir; # Continue searching up
    in
    findUp workingDir;

  # Main function to locate parent by multiple children
  locateParentByChildren' =
    {
      children,
      workingDir ? (getEnv "PWD"),
    }:
    let
      # Convert input to list if it's not already
      childrenList = toList children;

      # Try to find parent directory for each child
      # Stop after first successful find
      findFirst =
        remaining:
        if remaining == [ ] then
          null
        else
          let
            result = locateParentByChild' (head remaining);
          in
          if result != null then result else findFirst (tail remaining);
    in
    findFirst childrenList;

  test = locateParentByChildren' {
    children = [
      # "flake.nix"
      # "flake.lock"
      "Cargo.lock"
      "Cargo.toml"
      ".git"
      ".gitignore"
      ".envrc"
      ".cargo.lock"
      "package.json"
    ];
  };

}
