{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Native Imports

  inherit (pkgs) fetchFromGitHub;
  inherit (builtins) baseNameOf getEnv pathExists;
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
    pathsIgnored
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
        in {
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
            mkOption {
              description = "Process ignore checks based on the .dotignore file at the project root";
              default = _pathList: check _pathList toIgnore;
            };

          perGit =
            let
              toIgnore = splitString "\n" (fileContents (locateProjectRoot + "/.gitignore")) ++ [
                ".git"
                ".gitignore"
              ];
            in
            _pathList: check _pathList toIgnore;
        };
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
    locateParentByChild = mkOption {
      description = "Find the absolute path of the first parent directory of an item or a list of children.";
      example = ''parentByChild "src" ==> "/path/to/project"'';
      default =
        _child:
        let
          result = locateDominatingFile _child ./.;
          nullOrLocation = if result != null then builtins.toString result.path else null;
        in
        nullOrLocation;
    };
    locateParentByChildren = mkOption {
      description = "Find the absolute path of the first parent directory of an item or a list of children.";
      example = ''parentByChildren "src" ==> "/path/to/project"'';
      default =
        _children:
        let
          search = _child: locateDominatingFile _child ./.;
          result = filter (_p: _p != null) (map search (toList _children));
          nullOrLocation = if length result > 0 then (head result).path else null;
        in
        nullOrLocation;
    };
    locateParentByName = mkOption {
      description = "Find the absolute path of a specific path (by name) in a parent directory.";
      example = ''parentByName "src" ==> "/path/to/project/src"'';
      default =
        _name:
        let
          result = locateParentByChildren _name;
          nullOrLocation = if result != null then result + "/${_name}" else null;
        in
        nullOrLocation;
    };
    locateParentByNameOrChildren = mkOption {
      description = "Find the absolute path of a parent directory by name, falling back to files or a list of files for search.";
      example = ''locateParentByNameOrChildren "src" [".git" ".gitignore" ".flake.nix"] ==> "/path/to/project/root"'';
      default =
        _name: _children:
        let
          byName = locateParentByName _name;
          byChildren = locateParentByChildren _children;
          nullOrLocation = if byName != null then byName else byChildren;
        in
        nullOrLocation;
    };
    locateProjectRoot = mkOption {
      description = "Find the absolute path of the project root.";
      example = ''locateProjectRoot ==> "/path/to/project/root"'';
      default =
        let
          nullOrLocation = locateParentByChildren [
            ".git"
            ".gitignore"
            ".envrc"
            ".cargo.lock"
            "flake.lock"
            "flake.nix"
            "package.json"
            "Cargo.lock"
            "Cargo.toml"
          ];
        in
        nullOrLocation;
    };
    nullOrPathOf = mkOption {
      default =
        _path:
        let
          checkPath = tryEval _path;
        in
        if checkPath.success then checkPath.value else null;
    };
    githubPathOf = mkOption {
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
    test = { };
  };
}
