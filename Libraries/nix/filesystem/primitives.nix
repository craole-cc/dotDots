{
  _,
  # __moduleRef,
  lib,
  src,
  ...
}: let
  inherit (_.filesystem.predicates) pathExists;
  inherit (_.types.predicates) isAttrs isList isPath isString typeOf;
  inherit (lib.strings) concatStringsSep hasPrefix;

  exports = {
    internal = {
      inherit
        concat
        toPath
        ground
        construct
        ;
    };
    external = {};
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

  `store` is a proper Nix path value (importable as a module, usable in
  `imports`). `local` is a string for interpolation and display. When the
  resolved path does not exist on disk, `store` is `null` and `local` is
  still returned.

  Accepts any of:
  - a Nix path literal  (`./foo`, `/abs/path`)
  - an absolute string  (`"/abs/path"`)
  - a relative string   (`"rel/path"`) — resolved against `src`
  - a list of segments  (`["a" "b"]`) — joined and resolved against `src`

  # Type
  ```
  toPath :: path | string | [string]
          -> { store :: path | null, local :: string }
  ```

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
    #> Unpack into a normalised attrset
    unpacked =
      if isAttrs arg
      then arg
      else {path = arg;};
    raw = unpacked.path or arg;

    #> Normalise raw → absolute local string
    localStr =
      if isList raw
      then "${toString src}/${concatStringsSep "/" raw}"
      else if isPath raw
      then toString raw
      else if isString raw && hasPrefix "/" raw
      then raw
      else "${toString src}/${raw}";

    #> Resolve store path, null-safe
    storePath =
      if pathExists localStr
      then /. + localStr
      else null;
  in {
    store = storePath;
    local = localStr;
  };

  /**
    Resolve a root directory into a `{ store, local }` pair.

    Thin wrapper over `toPath` that defaults `root` to `src`.

    # Type
  ```
    ground :: { root :: path? } -> { store :: path | null, local :: string }
  ```

    # Examples
  ```nix
    ground {}
    # => { store = /home/…/dotDots; local = "/home/…/dotDots"; }

    ground { root = ./Libraries; }
    # => { store = /home/…/dotDots/Libraries; local = "/home/…/dotDots/Libraries"; }

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

    `store` is a proper Nix path value safe to use in `imports`. `local` is a
    string for interpolation. Accepts flexible calling patterns — attrset, bare
    string, or bare list. Root defaults to `src`.

    # Type
  ```
    construct :: { root :: path?, stem :: string | [string]? } | string | [string]
              -> { store :: path | null, local :: string }
  ```

    # Examples
  ```nix
    construct {}
    # => { store = /home/…/dotDots; local = "/home/…/dotDots"; }

    construct ["Libraries" "nix"]
    # => { store = /home/…/dotDots/Libraries/nix; local = "/home/…/dotDots/Libraries/nix"; }

    construct { stem = ["API" "nix" "hosts"]; }
    # => { store = /home/…/dotDots/API/nix/hosts; local = "/home/…/dotDots/API/nix/hosts"; }

    construct { root = ./Libraries; stem = ["nix"]; }
    # => { store = /home/…/dotDots/Libraries/nix; local = "/home/…/dotDots/Libraries/nix"; }
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

    joinStr = basePath:
      if basePath == null
      then null
      else if stem == [] || stem == ""
      then toString basePath
      else
        concat {
          root = toString basePath;
          inherit stem;
        };

    joinPath = basePath:
      if basePath == null
      then null
      else if stem == [] || stem == ""
      then basePath
      else
        basePath
        + (
          "/"
          + (
            if isList stem
            then concatStringsSep "/" stem
            else stem
          )
        );
  in {
    store = joinPath base.store;
    local = joinStr base.local;
  };
in
  exports.internal
