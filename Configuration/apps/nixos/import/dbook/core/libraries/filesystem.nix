{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Native Imports

  inherit (pkgs) fetchFromGitHub;
  inherit (builtins)
    baseNameOf
    getEnv
    storePath
    pathExists
    ;
  # inherit (lib)
  #   any
  #   elem
  #   filter
  #   length
  #   ;
  inherit (lib.lists)
    any
    elem
    filter
    toList
    foldl'
    head
    tail
    ;
  inherit (lib.strings)
    stringToCharacters
    hasSuffix
    splitString
    removeSuffix
    fileContents
    ;
  inherit (lib.attrsets) nameValuePair listToAttrs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.options) mkOption;

  #| Extended Imports
  inherit (config) DOTS;

  base = "lib";
  mod = "filesystem";

  inherit (DOTS.${base}.lists)
    prep
    clean
    infixed
    suffixed
    ;

  cfg = DOTS.${base}.${mod};
  inherit (cfg)
    pathOf
    pathOfPWD
    pathsIgnored
    pathsIn
    locateGitRoot
    pathsIgnoredCheck
    locateParentByChild
    locateParentByChildren
    locateParentByName
    ;
in
{
  options.DOTS.${base}.${mod} = {
    pathOf = mkOption {
      description = "Obtains the absolute path of a given file or directory, relative to the project root.";
      example = "
      pathOf \"src/configurations/user/review/craole.bac.nix\"
      => \"/etc/nixos/src/configurations/user/review/craole.bac.nix\"
      ";
      default =
        _path:
        foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x + y) "" (
          stringToCharacters (toString _path)
        );
    };

    pathOfPWD = mkOption {
      description = "Returns the current working directory.";
      default = getEnv "PWD";
    };

    pathOrNull = mkOption {
      description = "";
      default = _path: if pathExists (pathOf _path) then pathOf _path else null;
    };

    pathsIn = mkOption {
      description = "Recursively list path items including directories, files and modules";
      default =
        path:
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

          #| Utility
          trimNix = _file: removeSuffix ".nix" _file;

          #| Paths
          path' = pathOf path;
          paths = listFilesRecursive path';
          isBaseModule = path: isInDir path path';

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
          inherit (lists) Nix;

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
    };

    pathsIgnoredCheck = mkOption {
      description = "Processes ignore checks based on the .dotignore file at the project root";
      default =
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
    };

    pathsIgnored = {
      perDots = mkOption {
        description = "Process ignore checks based on the .dotignore file at the project root";
        default =
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
          pathList: pathsIgnoredCheck pathList toIgnore;
      };
      perGit = mkOption {
        description = "Process ignore checks based on the .gitignore file at the project root";
        default =
          let
            # TODO: Include all .gitignore files up to the git root
            toIgnore = splitString "\n" (fileContents locateGitRoot);
          in
          pathList: pathsIgnoredCheck pathList toIgnore;
      };
    };

    importModules = mkOption {
      # TODO: Move to nixpkgs as it will cause infinite recursion here.
      description = "List all nix paths in a directory.";
      example = ''nixModulesToImport "path/to/directory"'';
      default =
        _path:
        let
          modules = (pathsIn _path).perNix.list.paths;
        in
        map (_module: import _module) modules;
    };

    locateParentByChild = mkOption {
      description = "Find the absolute path of the first parent directory of an item or a list of children.";
      example = ''parentByChild "src" ./. ==> "/path/to/project"'';
      default =
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
    };

    locateParentByChildren = mkOption {
      description = "Find the absolute path of the first parent directory of an item or a list of children.";
      example = ''parentByChildren "src" ==> "/path/to/project"'';
      default =
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
    };

    locateParentByName = mkOption {
      description = "Find the absolute path of a specific path (by name) in a parent directory.";
      example = ''parentByName "src" ==> "/path/to/project/src"'';
      default =
        name:
        let
          result = locateParentByChildren { children = name; };
          nullOrLocation = if result != null then result + "/${name}" else null;
        in
        nullOrLocation;
    };

    locateParentByNameOrChildren = mkOption {
      description = "Find the absolute path of a parent directory by name, falling back to files or a list of files for search.";
      example = ''locateParentByNameOrChildren "src" [".git" ".gitignore" ".flake.nix"] ==> "/path/to/project/root"'';
      default =
        name: children:
        let
          byName = locateParentByName name;
          byChildren = locateParentByChildren { inherit children; };
          nullOrLocation = if byName != null then byName else byChildren;
        in
        nullOrLocation;
    };

    locateProjectRoot = mkOption {
      description = "Find the absolute path of the project root.";
      example = ''locateProjectRoot ==> "/path/to/project/root"'';
      default = locateParentByChildren {
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
    };

    locateFlake = mkOption {
      description = "Find the absolute path of the git root.";
      example = "locateGitRoot ==> \"/path/to/project/root\"";
      default = locateParentByChildren {
        children = [
          "flake.lock"
          "flake.nix"
        ];
      };
    };

    locateNixos = mkOption {
      description = "Find the absolute path of the git root.";
      example = "locateGitRoot ==> \"/path/to/project/root\"";
      default = locateParentByChild "configuration.nix" pathOfPWD;
    };

    locateGitRoot = mkOption {
      description = "Find the absolute path of the git root.";
      example = "locateGitRoot ==> \"/path/to/project/root\"";
      default = locateParentByChild ".git" pathOfPWD;
    };

    pathOfGitHub = mkOption {
      description = "Fetches the contents of a GitHub repository and returns the absolute path to the .nix file.";
      default =
        {
          owner,
          repo,
          rev,
          sha256,
        }:
        storePath (fetchFromGitHub {
          inherit
            owner
            repo
            rev
            sha256
            ;
        });
    };

    tests = mkOption {
      description = "Tests for {{base}}.{{mod}}";
      default = with cfg; {
        pathOf = pathOf ./.;
        pathOfPWD = pathOfPWD;
        pathOrNull = pathOrNull (pathOfPWD + "/none-existent-path");
        pathsIn = pathsIn ./.; 

      };
    };
  };
}
