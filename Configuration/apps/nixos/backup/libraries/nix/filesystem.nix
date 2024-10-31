{
  config,
  lib,
  pkgs,
  ...
}:
let
  mod = "filesystem";

  #| External libraries
  inherit (builtins) baseNameOf tryEval storePath;
  inherit (lib)
    any
    elem
    filter
    head
    length
    ;
  inherit (lib.lists)
    toList
    foldl'
    # unique
    # concatMap
    # naturalSort
    ;
  inherit (lib.strings)
    stringToCharacters
    hasPrefix
    hasSuffix
    hasInfix
    splitString
    removeSuffix
    replaceStrings
    fileContents
    ;
  inherit (lib.attrsets)
    # filterAttrs
    # genAttrs
    # mapAttrs
    # mapAttrs'
    attrNames
    attrValues
    nameValuePair
    listToAttrs
    ;
  inherit (lib.filesystem)
    locateDominatingFile
    # pathIsDirectory
    # pathIsRegularFile
    listFilesRecursive
    ;
  inherit (lib.options) mkOption;
  inherit (pkgs) fetchFromGitHub;

  #| Internal libraries
  inherit (config) dot;
  inherit (dot.libraries.lists)
    prep
    clean
    infixed
    suffixed
    ;
in
{
  options.dot.libraries.${mod} = with config.dot.libraries.${mod}; {
    pathOf =
      let
        absolute = path: if hasPrefix "/" path then path else locateProjectRoot + "/${path}";
        normalized =
          path:
          foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x + y) "" (
            stringToCharacters (toString path)
          );
      in
      mkOption {
        description = "Obtains the absolute path of a given file or directory, relative to the project root.";
        default = path: normalized (absolute path);
      };

    listPaths =
      let

        #| Validation
        # isModuleOf = path: file: path == dirOf file;
        isNixModule = file: hasSuffix ".nix" file;
        isNixSpecial =
          file:
          any (suffix: hasSuffix suffix file) [
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
        trimNix = file: removeSuffix ".nix" file;
      in
      mkOption {
        description = "Recursively list path items including directories, files and modules";
        default =
          path:
          let
            path' = pathOf path;
            paths = listFilesRecursive path';
            isBaseModule = file: dirOf file == path';

            #| Lists
            lists = rec {
              all = prep (filter (p: p != path') (paths ++ map (p: dirOf p) paths));
              dot = ignore.perDot all;
              nix = rec {
                base = filter (p: isNixModule p && isBaseModule p && !isNixSpecial p) dot;
                sub = {
                  dir = map (p: dirOf p) (filter (p: !isBaseModule p && isNixModule p && isNixSpecial p) dot);
                  file = filter (
                    p: !isBaseModule p && !isNixSpecial p && !elem p sub.dir && (!elem (dirOf p) sub.dir)
                  ) dot;
                };
                paths = base ++ sub.dir ++ sub.file;
                names = map (p: trimNix p) (map (p: baseNameOf p) paths);
              };
            };

            #| Sets
            attrs = {
              all = listToAttrs (map (p: nameValuePair (baseNameOf p) p) lists.all);
              dot = listToAttrs (map (p: nameValuePair (baseNameOf p) p) lists.dot);
              nix = listToAttrs (map (p: nameValuePair (trimNix (baseNameOf p)) p) lists.nix.paths);
            };
          in
          {
            inherit lists attrs;

            all = {
              list = lists.all;
              attrs = attrs.all;
            };

            dot = {
              list = lists.dot;
              attrs = attrs.dot;
            };

            nix = {
              list = {
                inherit (lists.nix)
                  base
                  sub
                  paths
                  names
                  ;
              };
              attrs = attrs.nix;
            };
          };
      };

    ignore =
      let
        check =
          pathList: ignoreList:
          clean
            (suffixed {
              list =
                (infixed {
                  list = pathList;
                  target = map (p: "/" + p + "/") ignoreList;
                }).inverted;
              target = map (p: "/" + p) ignoreList;
            }).inverted;
      in
      {
        perDot =
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
            default = pathList: check pathList toIgnore;
          };

        perGit =
          let
            toIgnore = splitString "\n" (fileContents (locateProjectRoot + "/.gitignore")) ++ [
              ".git"
              ".gitignore"
            ];
          in
          mkOption {
            description = "Process ignore checks based on the .dotignore file at the project root";
            default = pathList: check pathList toIgnore;
          };
      };
    importModules = mkOption {
      description = "List all nix paths in a directory.";
      example = ''nixModulesToImport "path/to/directory"'';
      default =
        path:
        let
          modules = (listPaths path).nix.list.paths;
        in
        map (module: import module) modules;
    };

    locateParentByChildren = mkOption {
      description = "Find the absolute path of the first parent directory of an item or a list of children.";
      example = ''parentByChildren "src" ==> "/path/to/project"'';
      default =
        children:
        let
          search = child: locateDominatingFile child ./.;
          result = filter (path: path != null) (map search (toList children));
          nullOrLocation = if length result > 0 then (head result).path else null;
        in
        nullOrLocation;
    };

    locateParentByName = mkOption {
      description = "Find the absolute path of a specific path (by name) in a parent directory.";
      example = ''parentByName "src" ==> "/path/to/project/src"'';
      default =
        name:
        let
          result = locateParentByChildren name;
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
          byChildren = locateParentByChildren children;
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
            ".flake.nix"
            ".envrc"
            ".cargo.lock"
            "package.json"
            "Cargo.lock"
            "Cargo.toml"
          ];
        in
        nullOrLocation;
    };

    mkSource = mkOption {
      description = "Process ignore checks based on the .dotignore file at the project root";
      example = ''mkSourceNix "path/to/directory"'';
      default =
        home:
        let
          inherit ((listPaths home).nix) attrs list;
        in
        {
          inherit home attrs;
          inherit (list) names paths;
        };
    };

    nullOrPathOf = mkOption {
      default =
        path:
        let
          checkPath = tryEval path;
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
  };
}
