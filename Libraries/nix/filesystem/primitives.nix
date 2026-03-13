{
  _,
  # __moduleRef,
  lib,
  src,
  ...
}: let
  inherit (builtins) pathExists getFlake;
  inherit (_.types.predicates) isAttrs isList isPath isString typeOf;
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.strings) concatStringsSep hasPrefix;

  exports = {
    internal = {
      inherit
        concat
        toPath
        ground
        construct
        ;
      getFlake = getFlake';
    };
    external = {};
  };

  getFlake' = {
    self ? {},
    path ? ./.,
  }: let
    # Pure flake resolution primitive - NO lib dependency
    hasFlakeNix = pathExists (toString path + "/flake.nix");
    derived =
      if hasFlakeNix
      then getFlake (toString path)
      else {};
  in
    if self != {}
    then self
    else derived;

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

  Replaces both deprecated `builtins.toPath` (string → absolute path) and
  `builtins.path` (path → store copy with options).

  Accepts any of:
  - a Nix path literal  (`./foo`, `/abs/path`)
  - an absolute string  (`"/abs/path"`)
  - a relative string   (`"rel/path"`) — resolved against `src`
  - a list of segments  (`["a" "b"]`) — joined and resolved against `src`
  - an attrset with optional `builtins.path` knobs (see Arguments)

  When the resolved path does not exist on disk, `store` is `null` and
  `local` is still returned — callers handle missing paths gracefully.

  # Type
  ```
  toPath :: path | string | [string]
          | { path      :: path | string | [string]
            , name      :: string?
            , filter    :: (string -> string -> bool)?
            , recursive :: bool?
            , sha256    :: string?
            }
          -> { store :: string | null, local :: string }
  ```

  # Arguments
  - `path`      — the path to resolve (required when passing an attrset)
  - `name`      — label in the store path             (default: `"path"`)
  - `filter`    — `builtins.filterSource`-style fn    (default: keep all)
  - `recursive` — hash the NAR (`true`) or flat file  (default: `true`)
  - `sha256`    — expected hash; enables pure-eval     (default: unset)

  # Examples
  ```nix
  toPath ./.
  # => { store = "/nix/store/…-path"; local = "/home/…/dotDots"; }

  toPath "/home/user/docs"
  # => { store = "/nix/store/…-path"; local = "/home/user/docs"; }

  toPath "Libraries"
  # => { store = "/nix/store/…-path"; local = "/home/…/dotDots/Libraries"; }

  toPath ["Libraries" "nix"]
  # => { store = "/nix/store/…-path"; local = "/home/…/dotDots/Libraries/nix"; }

  toPath { path = ./Libraries; name = "libs"; }
  # => { store = "/nix/store/…-libs"; local = "/home/…/dotDots/Libraries"; }

  toPath { path = ./file.txt; recursive = false; sha256 = "sha256-…"; }
  # => { store = "/nix/store/…-path"; local = "/home/…/dotDots/file.txt"; }

  toPath "/nonexistent"
  # => { store = null; local = "/nonexistent"; }
  ```
  */
  toPath = arg: let
    # 1. Unpack into a normalised attrset
    unpacked =
      if isAttrs arg
      then arg
      else {path = arg;};

    raw = unpacked.path      or arg;
    name = unpacked.name      or "path";
    filter = unpacked.filter    or null;
    recursive = unpacked.recursive or null;
    sha256 = unpacked.sha256    or null;

    # 2. Normalise raw → absolute local string
    localStr =
      if isList raw
      then "${toString src}/${concatStringsSep "/" raw}"
      else if isPath raw
      then toString raw
      else if isString raw && hasPrefix "/" raw
      then raw # already absolute
      else "${toString src}/${raw}"; # relative → anchor to src

    # 3. Build builtins.path args, forwarding optional knobs only when set
    pathArgs =
      {
        path = localStr;
        inherit name;
      }
      // optionalAttrs (filter != null) {inherit filter;}
      // optionalAttrs (recursive != null) {inherit recursive;}
      // optionalAttrs (sha256 != null) {inherit sha256;};

    # 4. Resolve store path, null-safe
    storeStr =
      if builtins.pathExists localStr
      then toString (builtins.path pathArgs)
      else null;
  in {
    store = storeStr;
    local = localStr;
  };

  /**
  Resolve a root directory into a `{ store, local }` pair.

  Thin wrapper over `toPath` that names the store path `"dotDots"` and
  defaults `root` to the flake/expression `src`. Use this when you want
  a stable, named store entry for the project root rather than the generic
  `"path"` label that `toPath` uses.

  When `root` does not exist on disk, `store` is `null` and `local` is
  still returned.

  # Type
  ```
  ground :: { root :: path?, name :: string? }
         -> { store :: string | null, local :: string }
  ```

  # Arguments
  - `root` — the directory to ground; defaults to `src`
  - `name` — label used in the store path; defaults to `"dotDots"`

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
  Build a resolved `{ store, local }` path from a root and a stem.

  Accepts flexible calling patterns — pass an attrset, a bare string, or a
  bare list and `construct` normalises it internally. The root defaults to
  `src` and is resolved through `ground` to produce a named store entry.

  When `root` does not exist on disk, `store` is `null` and `local` is
  still returned.

  # Type
  ```
  construct :: { root :: path?, stem :: string | [string]? }
             | string
             | [string]
             -> { store :: string | null, local :: string }
  ```

  # Calling patterns
  ```nix
  construct {}                                   # root only, no stem
  construct { stem = …; }                        # src root, explicit stem
  construct { root = …; stem = …; }              # explicit root and stem
  construct "some/stem"                          # bare string → stem
  construct ["some" "stem"]                      # bare list → stem
  ```

  # Examples
  ```nix
  construct {}
  # => { store = "/nix/store/…-dotDots"; local = "/home/…/dotDots"; }

  construct "Libraries"
  # => { store = "/nix/store/…-dotDots/Libraries"; local = "/home/…/dotDots/Libraries"; }

  construct ["Libraries" "nix"]
  # => { store = "/nix/store/…-dotDots/Libraries/nix"; local = "/home/…/dotDots/Libraries/nix"; }

  construct { stem = ["API" "nix" "hosts"]; }
  # => { store = "/nix/store/…-dotDots/API/nix/hosts"; local = "/home/…/dotDots/API/nix/hosts"; }

  construct { root = ./Libraries; stem = ["nix"]; }
  # => { store = "/nix/store/…-Libraries/nix"; local = "/home/…/dotDots/Libraries/nix"; }
  ```
  */
  construct = arg: let
    normalized =
      if isAttrs arg
      then arg
      else if
        isString arg
        || isList arg
      then {stem = arg;}
      else throw "construct: expected attrset, string, or list — got: ${typeOf arg}";

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
in
  exports.internal
