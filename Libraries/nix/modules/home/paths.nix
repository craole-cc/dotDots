{
  _,
  lib,
  ...
}: let
  inherit (_.types.predicates) isList;
  inherit (_.content.fallback) orDefault;
  inherit (_.attrsets.access) nestedOr;
  inherit (_.filesystem.tree) wallman;
  inherit (builtins) getEnv;
  inherit (lib.attrsets) mapAttrs mapAttrsToList;
  inherit (lib.lists) elemAt head toList;
  inherit
    (lib.strings)
    concatMapStringsSep
    hasPrefix
    removePrefix
    removeSuffix
    splitString
    ;

  exports = rec {
    internal = {
      inherit resolve session;
      mkUserPath = resolve;
      mkSessionPaths = session;
    };
    external = {
      inherit
        (internal)
        mkUserPath
        mkSessionPaths
        ;
    };
  };

  # ── resolve ───────────────────────────────────────────────────────────────

  /**
  Resolve a single user-configurable path to an absolute filesystem string.

  Looks up `path` in `user.paths` and falls back to `default` when absent.
  The resolved value is anchored against `dots` or `home` based on its
  prefix, or against the effective `root` directory for bare relative paths.

  Supported prefixes:
  - `/…`        — absolute, returned unchanged
  - `root:/…`   — treated as absolute, returned unchanged
  - `dots:…`    — resolved relative to `dots`
  - `$DOTS/…`   — resolved relative to `dots`
  - `home:…`    — resolved relative to `home`
  - `$HOME/…`   — resolved relative to `home`
  - bare string — resolved relative to the effective `root` dir

  # Type
  ```
  resolve :: {
    default :: string ,
    root    :: string? ,
    path    :: [string]? ,
    dots    :: string ,
    home    :: string ,
    user    :: AttrSet ,
  } -> string
  ```

  # Arguments
  - `default` — fallback when `user.paths` has no entry at `path`
  - `root`    — base for bare relatives: `"home"`, `"dots"`, or an absolute
                path string (default: `"home"`)
  - `path`    — key path into `user.paths` to query (default: `[]`)
  - `dots`    — absolute path to the dotfiles root
  - `home`    — absolute path to the user home directory
  - `user`    — user attrset; `user.paths` is queried when `path` is set

  # Examples
  ```nix
  resolve { inherit home dots user; default = "home:Pictures/Wallpapers"; }
  # => "/home/craole/Pictures/Wallpapers"

  resolve { inherit home dots user; default = "dots:Assets/Images/logo.png"; }
  # => "/home/…/dotDots/Assets/Images/logo.png"

  resolve {
    inherit home dots user;
    path    = ["wallpapers" "primary"];
    default = "home:Pictures/Wallpapers";
  }
  # => user.paths.wallpapers.primary if set, else "/home/craole/Pictures/Wallpapers"
  ```
  */
  resolve = {
    default,
    root ? "home",
    path ? [],
    dots,
    home,
    user,
  }: let
    absolute =
      if root == "dots"
      then dots
      else if
        root
        == "home"
        || root == ""
      then home
      else removeSuffix "/" root;

    path' = toList path;
    relative = orDefault {
      content =
        if path' != []
        then
          nestedOr {
            attrs = user.paths or {};
            path = path';
            default = null;
          }
        else null;
      inherit default;
    };
  in
    if hasPrefix "/" relative || hasPrefix "root:" relative
    then relative
    else if hasPrefix "dots:" relative || hasPrefix "$DOTS/" relative
    then dots + "/" + removePrefix "dots:" (removePrefix "$DOTS/" relative)
    else if hasPrefix "home:" relative || hasPrefix "$HOME/" relative
    then absolute + "/" + removePrefix "home:" (removePrefix "$HOME/" relative)
    else absolute + "/" + relative;

  # ── session ───────────────────────────────────────────────────────────────

  /**
  Derive the full set of runtime paths for a user session.

  Builds wallpaper, avatar, and API paths from host/user/config context.
  Every path is resolved through `resolve` so users can override any
  individual entry via `user.paths`.

  # Type
  ```
  session :: { config :: AttrSet
             , host   :: AttrSet
             , user   :: AttrSet
             , pkgs   :: AttrSet
             , paths  :: AttrSet?
             } -> AttrSet
  ```

  # Returns
  ```
  { api        :: { host :: string, user :: string }
  , avatars    :: { session :: string, media :: string }
  , dots       :: string
  , home       :: string
  , wallpapers :: { all, primary, dark, light, monitors, manager }
  }
  ```
  */
  session = {
    config,
    host,
    user,
    pkgs,
    tree ? {},
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
      raw = nestedOr {
        attrs = user.paths or {};
        path = ["wallpapers" "all"];
        default = tree.local.res.wallpaper or "home:Pictures/Wallpapers";
      };

      all =
        if isList raw
        then
          map (p:
            resolve {
              inherit home dots user;
              default = p;
            })
          raw
        else [
          (resolve {
            inherit home dots user;
            path = ["wallpapers" "all"];
            default = "home:Pictures/Wallpapers";
          })
        ];

      primary = resolve {
        inherit home dots user;
        path = ["wallpapers" "primary"];
        default = head all;
      };

      dark = resolve {
        inherit home dots user;
        path = ["wallpapers" "dark"];
        default = primary + "/dark.jpg";
      };

      light = resolve {
        inherit home dots user;
        path = ["wallpapers" "light"];
        default = primary + "/light.jpg";
      };

      monitors =
        mapAttrs (name: cfg: let
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

          directory = resolve {
            inherit home dots user;
            path = ["wallpapers" "monitors" name "directory"];
            default = primary + "/${resolution}";
          };
          monDark = resolve {
            inherit home dots user;
            path = ["wallpapers" "monitors" name "dark"];
            default = directory;
          };
          monLight = resolve {
            inherit home dots user;
            path = ["wallpapers" "monitors" name "light"];
            default = directory;
          };
          cache = directory + "/.cache";
          current = primary + "/current-${name}.jpg";

          manager = replaceVarsWith {
            src = wallman; # _.filesystem.meta.wallman = ./wallman.sh (in filesystem/)
            name = "wallman-${name}";
            replacements = {
              inherit name resolution directory current;
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
        })
        host.devices.display;

      manager = writeShellScriptBin "wallman" ''
        #!/bin/sh
        set -eu
        if [ $# -lt 1 ]; then
          printf "Usage: %s <command> [options]\n" "$0" >&2
          exit 1
        fi
        ${concatMapStringsSep "\n"
          (mgr: ''${mgr} "$@" || true'')
          (mapAttrsToList (_: cfg: cfg.manager) monitors)}
      '';
    in {inherit all primary dark light monitors manager;};

    avatars = {
      session = resolve {
        inherit home dots user;
        path = ["avatars" "session"];
        default = "root:/assets/kurukuru.gif";
      };
      media = resolve {
        inherit home dots user;
        path = ["avatars" "media"];
        default = "root:/assets/kurukuru.gif";
      };
    };

    api = {
      host = resolve {
        inherit home dots user;
        default = "dots:API/hosts/${host.name}/default.nix";
      };
      user = resolve {
        inherit home dots user;
        default = "dots:API/users/${user.name}/default.nix";
      };
    };
  in
    tree // {inherit api avatars dots home wallpapers;};
in
  exports.internal // {_rootAliases = exports.external;}
