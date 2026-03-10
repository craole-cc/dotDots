{
  _,
  __moduleRef,
  lib,
  src,
  # paths,
  ...
}: let
  inherit (_.attrsets.access) getIn;
  inherit (_.content.empty) isEmpty isNotEmpty;
  inherit (_.content.fallback) orDefault firstNonEmpty;
  inherit (_.debug.assertions) mkTest;
  inherit (_.debug.module) mkModuleDebug;
  inherit (_.debug.runners) runTests;
  inherit (_.types.predicates) isAttrs isList isPath isString typeOf;
  inherit (builtins) getEnv;
  inherit (lib.asserts) assertMsg;
  inherit (lib.attrsets) mapAttrs mapAttrsRecursive mapAttrsToList optionalAttrs;
  inherit (lib.filesystem) dirOf;
  inherit (lib.lists) elemAt head toList;
  inherit
    (lib.strings)
    concatStringsSep
    hasPrefix
    hasSuffix
    removePrefix
    removeSuffix
    splitString
    concatMapStringsSep
    ;
  inherit (lib.trivial) pathExists;

  debug = mkModuleDebug __moduleRef;

  exports = rec {
    internal = {
      inherit
        construct
        ground
        concat
        mkDefault
        getDefaults
        flake
        flakeOrNull
        toPath
        stems
        ;
      flakePath = flakeOrNull;
    };

    external = {
      inherit (internal) flakePath;
    };
  };

  /**
  Join a root and stem into a single path string.

  Both `root` and `stem` may be a plain string or a list of path segments;
  lists are joined with `/` before concatenation.

  # Type
  ```
  concat :: { root :: string | [string], stem :: string | [string] } -> string
  ```

      # Examples
  ```nix
  concat { root = "/home/user"; stem = "documents/file.txt"; }
  # => "/home/user/documents/file.txt"

  concat { root = ["home" "user"]; stem = ["documents" "file.txt"]; }
  # => "/home/user/documents/file.txt"

  concat { root = "/var"; stem = ["log" "app" "output.log"]; }
  # => "/var/log/app/output.log"

  concat { root = ["var" "log"]; stem = "app/output.log"; }
  # => "/var/log/app/output.log"
  ```
  */
  concat = {
    root,
    stem,
  }: let
    normalize = part:
      if isList part
      then concatStringsSep "/" part
      else part;
  in "${normalize root}/${normalize stem}";

  /**
    Convert any path-like value into a normalised `{ store, local }` pair.

    Serves as a single replacement for both deprecated `builtins.toPath`
    (string → absolute path) and `builtins.path` (path → store copy with
    options).

    Accepts any of:
    - a Nix `path` literal  (`./foo`, `/abs/path`)
    - an absolute string    (`"/abs/path"`)
    - a relative string     (`"rel/path"`)  — resolved against `src`
    - a list of segments    (`["a" "b"]`)   — joined and resolved against `src`

    Optional `builtins.path` knobs are forwarded when producing the store path:
    - `name`      — label in the store path             (default: `"path"`)
    - `filter`    — `builtins.filterSource`-style fn    (default: keep all)
    - `recursive` — hash the NAR (`true`) or flat file  (default: `true`)
    - `sha256`    — expected hash; enables pure-eval     (default: unset)

    When the resolved path does not exist on disk, `store` is `null` and
    `local` is still returned.

    # Type
  ```
  toPath :: path | string | [string]
          | { path  :: path | string | [string]
            , name      :: string?
            , filter    :: (string -> string -> bool)?
            , recursive :: bool?
            , sha256    :: string?
            }
          -> { store :: string | null, local :: string }
  ```

    # Examples
  ```nix
  toPath ./.
  # => { store = "/nix/store/…-path";  local = "/home/…/dotDots"; }

  toPath "/home/user/docs"
  # => { store = "/nix/store/…-path";  local = "/home/user/docs"; }

  toPath "Libraries"
  # => { store = "/nix/store/…-path/Libraries"; local = "/home/…/dotDots/Libraries"; }

  toPath ["Libraries" "nix"]
  # => { store = "/nix/store/…-path";  local = "/home/…/dotDots/Libraries/nix"; }

  toPath { path = ./Libraries; name = "libs"; }
  # => { store = "/nix/store/…-libs";  local = "/home/…/dotDots/Libraries"; }

  toPath { path = ./file.txt; recursive = false; sha256 = "sha256-…"; }
  # => { store = "/nix/store/…-path";  local = "/home/…/dotDots/file.txt"; }
  ```
  */
  toPath = arg: let
    # -- 1. Unpack into { rawPath, name, filter, recursive, sha256 } ──────────
    unpacked =
      if isAttrs arg
      then arg
      else {path = arg;};

    raw = unpacked.path or arg;
    name = unpacked.name      or "path";
    filter = unpacked.filter    or null;
    recursive = unpacked.recursive or null;
    sha256 = unpacked.sha256    or null;

    # -- 2. Normalise raw → absolute string ───────────────────────────────────
    localStr =
      if isList raw
      then "${toString src}/${concatStringsSep "/" raw}"
      else if isPath raw
      then toString raw
      else if isString raw && hasPrefix "/" raw
      then raw #? already absolute
      else "${toString src}/${raw}"; #? relative → anchor to src

    # -- 3. Build builtins.path args, adding optional knobs only if set ────────
    pathArgs =
      {
        path = localStr;
        inherit name;
      }
      // optionalAttrs (filter != null) {inherit filter;}
      // optionalAttrs (recursive != null) {inherit recursive;}
      // optionalAttrs (sha256 != null) {inherit sha256;};

    # -- 4. Resolve store path, null-safe ─────────────────────────────────────
    storeStr =
      if builtins.pathExists localStr
      then toString (builtins.path pathArgs)
      else null;
  in {
    store = storeStr;
    local = localStr;
  };

  /**
  Resolve a local filesystem path into both its Nix store copy and its
  original on-disk location.

  `builtins.path` hashes and copies the directory into the store, producing
  a stable, content-addressed store path. The `local` field is the raw
  filesystem string (via `toString`) with no store involvement.

  If `root` does not exist on disk, `store` is `null` and `local` is still
  returned — this allows callers to handle missing paths gracefully.

  # Type
  ```
    ground :: { root :: path?, name :: string? } -> { store :: string | null, local :: string }
  ```

  # Arguments
  - `root`  — the directory to ground; defaults to the flake/expression `src`
  - `name`  — the human-readable label used in the store path; defaults to `"dotDots"`

  # Examples
  ```nix
  ground {}
  # => {
  #      store = "/nix/store/…-dotDots";
  #      local = "/home/craole/Downloads/public/dotDots";
  #    }

  ground { root = ./Libraries; name = "libs"; }
  # => {
  #      store = "/nix/store/…-libs";
  #      local = "/home/craole/Downloads/public/dotDots/Libraries";
  #    }

  ground { root = /nonexistent; }
  # => { store = null; local = "/nonexistent"; }
  ```
  */
  ground = {
    root ? src,
    name ? "dotDots",
  }:
    toPath {
      path = root;
      inherit name;
    };

  /**
  Pre-defined stem segments for well-known locations within the tree.

  Each group is an attrset whose `default` key is the canonical stem for
  that group and whose other keys are sub-locations built on top of it.
  Using `rec` lets sub-paths compose from `default` without repeating
  the prefix.

  These are plain lists of strings — pass them directly to `construct`
  or `concat` as the `stem` argument.

  # Examples
  ```nix
  stems.libs.nix       # => [ "Libraries" "nix" ]
  stems.api.hosts      # => [ "API" "nix" "hosts" ]
  stems.pkgs.overlays  # => [ "Packages" "nix" "overlays" ]
  ```
  */
  stems = {
    default = [];

    libs = rec {
      default = nix;
      nix = ["Libraries" "nix"];
      shellscript = ["Libraries" "shellscript"];
      rust = ["Libraries" "rust"];
    };

    api = rec {
      default = ["API" "nix"];
      hosts = default ++ ["hosts"];
      users = default ++ ["users"];
    };

    pkgs = rec {
      default = ["Packages" "nix"];
      global = default ++ ["global"];
      core = default ++ ["core"];
      home = default ++ ["home"];
      overlays = default ++ ["overlays"];
      plugins = default ++ ["plugins"];
    };

    templates = rec {
      default = ["Templates" "nix"];
      rust = default ++ ["rust"];
    };

    images = rec {
      default = ["Assets" "Images"];
      ascii = default ++ ["ascii"];
      logo = default ++ ["logo"];
      wallpaper = default ++ ["wallpaper"];
    };
  };

  /**
  Build a resolved `{ store, local }` path from a root and a stem.

  Accepts any of the following calling patterns:
  - `construct {}` — resolves to the root alone (both store and local)
  - `construct { stem = …; }` — root defaults to `src`, stem is appended
  - `construct { root = …; stem = …; }` — explicit root and stem
  - `construct "some/stem"` — bare string treated as stem, root defaults to `src`
  - `construct ["some" "stem"]` — bare list treated as stem, root defaults to `src`

  `stem` may be a string, a list of segments, or one of the pre-defined
  values from `stems` (e.g. `stems.api.hosts`).

  When `root` does not exist on disk, `store` is `null` and `local` is
  still returned.

  # Type
  ```
  construct :: { root :: path?, stem :: string | [string]? }
            | string
            | [string]
            -> { store :: string | null, local :: string }
  ```

  # Examples
  ```nix
  construct {}
  # => { store = "/nix/store/…-dotDots"; local = "/home/…/dotDots"; }

  construct "Libraries"
  # => { store = "/nix/store/…-dotDots/Libraries"; local = "/home/…/dotDots/Libraries"; }

  construct ["Libraries" "nix"]
  # => { store = "/nix/store/…-dotDots/Libraries/nix"; local = "/home/…/dotDots/Libraries/nix"; }

  construct { stem = stems.api.hosts; }
  # => { store = "/nix/store/…-dotDots/API/nix/hosts"; local = "/home/…/dotDots/API/nix/hosts"; }

  construct { root = ./Libraries; stem = stems.libs.nix; }
  # => { store = "/nix/store/…-Libraries/Libraries/nix"; local = "/home/…/dotDots/Libraries/Libraries/nix"; }
  ```
  */
  construct = arg: let
    normalized =
      if isAttrs arg
      then arg
      else if isString arg || isList arg
      then {stem = arg;}
      else throw "construct: expected an attrset, string, or list but got: ${typeOf arg}";

    root = normalized.root or src;
    stem = normalized.stem or [];

    base = ground {inherit root;};
    join = basePath:
      if basePath == null
      then null
      else if stem == [] || stem == ""
      then basePath
      else
        concat {
          root = basePath;
          inherit stem;
        };
  in {
    store = join base.store;
    local = join base.local;
  };

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
        then
          getIn {
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
  flakeOrNull :: { self? :: AttrSet, path? :: path | string } -> string | null
  ```
  */
  flakeOrNull = {
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
    result = flakeOrNull {inherit self path;};
  in
    if result != null
    then result
    else
      throw (debug.mkError {
        function = "flake";
        message = "'${toString path}' is not a valid flake path";
      });
in
  exports.internal // {_rootAliases = exports.external;}
