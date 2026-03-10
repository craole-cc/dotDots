{
  _,
  lib,
  src,
  __libraryPath,
  ...
}: let
  inherit (_.types.predicates) isString isList;
  inherit (_.values.empty) isNotEmpty;
  inherit (_.values.fallback) orDefault firstNonEmpty;
  inherit (_.attrsets.access) getIn;
  inherit (_.debug.module) mkModuleDebug;

  _debug = mkModuleDebug __libraryPath;
  inherit (lib.strings)
    concatStringsSep
    hasPrefix
    removePrefix
    removeSuffix
    splitString
    concatMapStringsSep
    ;
  inherit (lib.asserts) assertMsg;
  inherit (lib.attrsets) attrByPath mapAttrs mapAttrsToList;
  inherit (lib.debug) traceIf;
  inherit (lib.filesystem) dirOf;
  inherit (lib.trivial) pathExists;
  inherit (lib.lists) elemAt head toList;
  inherit (lib.strings) hasSuffix;
  inherit (builtins) getEnv;

  /**
  Construct a file path from a root directory and a stem.

  The stem may be a string or a list of path segments (joined with `/`).

  # Type
  ```nix
  construct :: { root :: string, stem :: string | [string] } -> string
  ```

  # Examples
  ```nix
  construct { root = "/home/user"; stem = "documents/file.txt"; }
  # => "/home/user/documents/file.txt"

  construct { root = "/var"; stem = ["log" "app" "output.log"]; }
  # => "/var/log/app/output.log"
  ```
  */
  construct = {
    root,
    stem,
  }:
    assert assertMsg (isNotEmpty root) "root must not be empty";
    assert assertMsg (isNotEmpty stem) "stem must not be empty"; "${root}/${
      if isList stem
      then concatStringsSep "/" stem
      else stem
    }";

  /**
  Resolve a user/host path value to an absolute filesystem path.

  Supports the following prefixes in `default` (or in the resolved value
  from `user.paths`):

  - Absolute paths (`/…`) — returned unchanged
  - `root:/…`             — returned unchanged (caller strips prefix)
  - `dots:…` / `$DOTS/…` — resolved relative to `dots`
  - `home:…` / `$HOME/…` — resolved relative to `home`
  - Bare relative paths   — resolved relative to the effective root dir

  The lookup path `path` (list of strings) is used to query `user.paths`;
  `default` is used when the key is absent or empty.

  # Type
  ```nix
  mkDefault :: {
    default  :: string,
    root     :: string?,
    path     :: [string]?,
    dots     :: string,
    home     :: string,
    user     :: AttrSet,
  } -> string
  ```
  */
  mkDefault = {
    default,
    root ? "home",
    path ? [],
    dots,
    home,
    user,
  }: let
    #> Resolve the base directory
    absolute =
      if root == "dots"
      then dots
      else if root == "home" || root == ""
      then home
      else removeSuffix "/" root;

    #> Get the value from user.paths, falling back to default
    path' = toList path;
    relative = orDefault {
      value =
        if path' != []
        then getIn {
          attrs = user.paths or {};
          inherit path';
          default = null;
        }
        else null;
      inherit default;
    };
  in
    if (hasPrefix "/" relative) || (hasPrefix "root:" relative)
    then relative
    else if (hasPrefix "dots:" relative) || (hasPrefix "$DOTS/" relative)
    then dots + "/" + removePrefix "dots:" (removePrefix "$DOTS/" relative)
    else if (hasPrefix "home:" relative) || (hasPrefix "$HOME/" relative)
    then absolute + "/" + removePrefix "home:" (removePrefix "$HOME/" relative)
    else absolute + "/" + relative;

  /**
  Derive default paths for a user session (wallpapers, avatars, API, etc.)
  from host, user, and config context.

  # Type
  ```nix
  getDefaults :: { config, host, user, pkgs, paths? } -> AttrSet
  ```
  */
  getDefaults = {
    config,
    host,
    user,
    pkgs,
    paths ? {},
    ...
  }: let
    inherit
      (pkgs)
      coreutils
      fd
      imagemagick
      replaceVarsWith
      ripgrep
      writeShellScriptBin
      ;
    inherit (host.paths) dots;
    home = config.home.homeDirectory or (getEnv "HOME");

    wallpapers = let
      raw = getIn {
        attrs = user.paths or {};
        path' = ["wallpapers" "all"];
        default = null;
      };
      all =
        if isList raw
        then
          map (
            p:
              mkDefault {
                inherit home dots user;
                default = p;
              }
          )
          raw
        else [
          (mkDefault {
            inherit home dots user;
            path = ["wallpapers" "all"];
            default = "home:Pictures/Wallpapers";
          })
        ];

      primary = mkDefault {
        inherit home dots user;
        path = ["wallpapers" "primary"];
        default = head all;
      };

      dark = mkDefault {
        inherit home dots user;
        path = ["wallpapers" "dark"];
        default = primary + "/dark.jpg";
      };

      light = mkDefault {
        inherit home dots user;
        path = ["wallpapers" "light"];
        default = primary + "/light.jpg";
      };

      monitors =
        mapAttrs (
          name: cfg: let
            transformation = cfg.transform or 0;
            rotation =
              if transformation == 1
              then 90
              else if transformation == 2
              then 180
              else if transformation == 3
              then 270
              else 0;

            isRotated = rotation == 90 || rotation == 270;
            isFlipped = rotation == 180;

            resolution =
              if isRotated
              then let
                parts = splitString "x" cfg.resolution;
                width = elemAt parts 0;
                height = elemAt parts 1;
              in "${height}x${width}"
              else cfg.resolution;

            directory = mkDefault {
              inherit home dots user;
              path = ["wallpapers" "monitors" name "directory"];
              default = primary + "/${resolution}";
            };
            monDark = mkDefault {
              inherit home dots user;
              path = ["wallpapers" "monitors" name "dark"];
              default = directory;
            };
            monLight = mkDefault {
              inherit home dots user;
              path = ["wallpapers" "monitors" name "light"];
              default = directory;
            };
            cache = directory + "/.cache";
            current = primary + "/current-${name}.jpg";
            manager = replaceVarsWith {
              src = ./wallman.sh;
              name = "wallman-${name}";
              replacements = {
                inherit
                  name
                  resolution
                  directory
                  current
                  ;
                cmdConvert = "${imagemagick}/bin/convert";
                cmdFd = "${fd}/bin/fd";
                cmdRg = "${ripgrep}/bin/rg";
                cmdLn = "${coreutils}/bin/ln";
                cmdShuf = "${coreutils}/bin/shuf";
                cmdRealpath = "${coreutils}/bin/realpath";
                cachePolarity = "${cache}/polarity.txt";
                cachePurity = "${cache}/purity.txt";
                cacheCategory = "${cache}/category.txt";
                cacheFavorite = "${cache}/favorite.txt";
              };
              isExecutable = true;
            };
          in {
            inherit
              cache
              current
              isFlipped
              isRotated
              manager
              name
              resolution
              rotation
              transformation
              ;
            dark = monDark;
            light = monLight;
            directory = directory;
          }
        )
        host.devices.display;

      #> Global wallpaper manager
      manager = writeShellScriptBin "wallman" ''
        #!/bin/sh
        set -eu

        if [ $# -lt 1 ]; then
          printf "Usage: %s <command> [options]\n" "$0" >&2
          exit 1
        fi

        ${concatMapStringsSep "\n" (mgr: ''${mgr} "$@" || true'') (
          mapAttrsToList (_: cfg: cfg.manager) monitors
        )}
      '';
    in {
      inherit all primary dark light monitors manager;
    };

    avatars = {
      session = mkDefault {
        inherit home dots user;
        path = ["avatars" "session"];
        default = "root:/assets/kurukuru.gif";
      };
      media = mkDefault {
        inherit home dots user;
        path = ["avatars" "media"];
        default = "root:/assets/kurukuru.gif";
      };
    };

    api = {
      host = mkDefault {
        inherit home dots user;
        default = "dots:API/hosts/${host.name}/default.nix";
      };
      user = mkDefault {
        inherit home dots user;
        default = "dots:API/users/${user.name}/default.nix";
      };
    };

    exports = {
      inherit api avatars dots home wallpapers;
      libs.shellscript = dots + "/Bin/shellscript";
    };
  in
    paths // exports;

  /**
  Try to resolve a flake root path. Returns the directory string if found,
  or null if the path is not a valid flake root.

  # Type
  ```nix
  tryFlake :: { self? :: AttrSet, path? :: path | string } -> string | null
  ```
  */
  tryFlake = {
    self ? {},
    path ? src,
  }: let
    pathStr = toString path;
  in
    if isNotEmpty (self.outPath or null)
    then self.outPath
    else if hasSuffix "/flake.nix" pathStr && pathExists pathStr
    then dirOf pathStr
    else if pathExists (pathStr + "/flake.nix")
    then pathStr
    else null;

  /**
  Resolve a flake root path, throwing if it cannot be determined.

  # Type
  ```nix
  flake :: { self? :: AttrSet, path? :: path | string } -> string
  ```
  */
  flake = {
    self ? {},
    path ? src,
  }: let
    result = tryFlake {inherit self path;};
  in
    if result != null
    then result
    else throw (_debug.mkError {
      function = "flake";
      message  = "'${toString path}' is not a valid flake path";
    });

  /**
  Build the `nixpkgs` source attribute set appropriate for the host class.

  Darwin uses `source`; NixOS uses `flake.source`.

  # Type
  ```nix
  source :: { host? :: AttrSet, root? :: any, inputs? :: AttrSet } -> AttrSet
  ```
  */
  source = {
    host ? {},
    root ? null,
    inputs ? {},
    ...
  }: let
    resolvedRoot = firstNonEmpty [
      root
      (inputs.nixpkgs or null)
    ];
  in
    if (host.class or "nixos") == "darwin"
    then {source = resolvedRoot;}
    else {flake.source = resolvedRoot;};

  exports = {
    inherit
      construct
      mkDefault
      getDefaults
      flake
      tryFlake
      source
      ;
  };
in
  exports
  // {
    _rootAliases = {
      buildPath = construct;
      getDefaultPaths = getDefaults;
      mkDefaultPath = mkDefault;
      flakePath = flake;
      flakePathOrNull = tryFlake;
      sourcePath = source;
    };
  }
