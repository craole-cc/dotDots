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
  pathofPWD = getEnv "PWD";

  /**
    pathof :: path -> absolute path

    "Obtains the absolute path of a given file or directory, relative to the project root."

    Parameters:
      _path = Path to convert to an absolute path.

    Returns: absolute path

    Example:
      pathof "src/configurations/user/review/craole.bac.nix"
      => "/etc/nixos/src/configurations/user/review/craole.bac.nix"
  */
  pathof =
    _path:
    foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x + y) "" (
      stringToCharacters (toString _path)
    );

  pathOrNull = _path: if pathExists (pathof _path) then pathof _path else null;
  /**
    "Recursively list path items including directories, files and modules

    Parameters:
      _path = Path to list.

    Returns:
      all = List of all items in the path.
      attrs = Paths as attrs.
      lists = Paths as lists.
      perDots = Paths as lists filtered by pathsIgnored.perDots.
      perNix = Paths as lists filtered by pathsIgnored.perNix.

    Example:
      pathsIn ./. ==> {
        all = { ... };
        attrs = { ... };
        lists = { ... };
        perDots = { ... };
        perNix = { ... };
      }
  */
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
      path' = pathof _path;
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
    child: workingDir:
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

  /**
    Find the absolute path of the first parent directory of an item or a list of children.

    Parameters:
      _children = List of children to search.

    Returns: absolute path

    Example:
      locateParentByChildren "src" ==> "/path/to/project"
  */
  locateParentByChildren =
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
            result = locateParentByChild (head remaining) workingDir;
          in
          if result != null then result else findFirst (tail remaining);
    in
    findFirst childrenList;

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
      result = locateParentByChildren { children = _name; };
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
      locateParentByNameOrChildren "src" [ ".flake.nix" ".git" ".gitignore"] ==> "/path/to/project/root"
  */
  locateParentByNameOrChildren =
    name: children:
    let
      byName = locateParentByName name;
      byChildren = locateParentByChildren { inherit children; };
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
  locateProjectRoot = locateParentByChildren {
    children = [
      # Nix
      "flake.nix"
      "flake.lock"
      ".envrc"

      # Rust
      "Cargo.lock"
      "Cargo.toml"

      # JavaScript/Node.js
      "package.json"
      "yarn.lock"
      "pnpm-lock.yaml"

      # Python
      "pyproject.toml"
      "Pipfile"
      "requirements.txt"
      "setup.py"
      "setup.cfg"

      # Java/Maven/Gradle
      "pom.xml"
      "build.gradle"
      "build.gradle.kts"

      # Ruby
      "Gemfile"
      "Gemfile.lock"

      # Go
      "go.mod"
      "go.sum"

      # PHP/Composer
      "composer.json"
      "composer.lock"

      # C/C++/CMake
      "CMakeLists.txt"
      "Makefile"

      # .NET
      "*.sln"
      "*.csproj"
      "*.fsproj"

      # CI/CD
      ".github/workflows"
      ".gitlab-ci.yml"
      "Jenkinsfile"

      # Docker
      "Dockerfile"
      ".dockerignore"

      # Git
      ".gitignore"
      ".git"

      # IDE/editor-specific directories
      ".idea" # IntelliJ-based IDEs (e.g., IDEA, PyCharm, WebStorm)
      ".vscode" # Visual Studio Code
      ".atom" # Atom editor
      ".eclipse" # Eclipse IDE
      ".metadata" # Eclipse workspace folder
      ".devcontainer" # VS Code development container
      ".vs" # Visual Studio
      ".editorconfig" # Editor configuration

      # Documentation
      "README"
      "README.md"
      "README.org"
      "LICENSE"
      "LICENSE.txt"
      "LICENSE.md"
      "COPYING"
      "COPYING.txt"
      "COPYING.md"
      "CONTRIBUTING"
      "CONTRIBUTING.md"
      "CONTRIBUTING.txt"
      "CHANGELOG.md"
      "NOTES.md"
      "NOTES.org"
      "TODO.org"
      "TODO.md"
    ];
  };
  /**
    Find the absolute path of the flake root.
  */
  locateFlakeRoot = locateParentByChildren {
    children = [
      "flake.lock"
      "flake.nix"
    ];
  };
  /**
    Find the absolute path of the nixos config root.
  */
  locateNixosRoot = locateParentByChild "configuration.nix" pathofPWD;
  /**
    Find the absolute path of the git root.
  */
  locateGitRoot = locateParentByChild ".git" pathofPWD;

  test = locateParentByChildren {
    children = [
      # Nix
      "flake.lock"
      "flake.nix"
      ".envrc"

      # Rust
      "Cargo.lock"
      "Cargo.toml"

      # JavaScript
      "package.json"

      # Git
      ".gitignore"
      ".git"
    ];
  };

}
