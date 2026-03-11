{
  _,
  lib,
  src,
  ...
}: let
  inherit (_.filesystem.primitives) construct;
  inherit (_.types.predicates) isAttrs;
  inherit (lib.attrsets) mapAttrs recursiveUpdateUntil;

  exports = {
    inherit stems mkPaths;
  };

  # ── Group constructors ─────────────────────────────────────────────────────

  /**
  Build a multi-language group where sibling languages share a common parent
  directory. Each language is a peer — none derives from another.

  `default` always points to `nix` as the project-primary language.

  Used for: `Libraries`, `Packages`, `API` — all follow the pattern
  `<parent>/<language>/`.

  # Type
  ```
  mkLangGroup :: parent :: [string]
              -> langs  :: { key :: string }
              -> { default :: [string], <key> :: [string], … }
  ```

  # Examples
  ```nix
  mkLangGroup ["Libraries"] { nix = "nix"; rust = "rust"; }
  # => {
  #      default     = ["Libraries" "nix"];
  #      nix         = ["Libraries" "nix"];
  #      rust        = ["Libraries" "rust"];
  #    }
  ```
  */
  mkLangGroup = parent: langs:
    {default = parent ++ ["nix"];}
    // mapAttrs (_: lang: parent ++ [lang]) langs;

  /**
  Build a nix-rooted group where sub-directories are functional categories,
  not languages. Everything chains from a single nix base.

  `default` is the base itself. Each entry appends a suffix list onto it.

  Used for: `Templates` — the nix directory is the root and sub-dirs are
  template types (`rust`, `shellscript`, `dev`, etc.).

  # Type
  ```
  mkNixGroup :: base    :: [string]
            -> entries :: { key :: [string] }
            -> { default :: [string], <key> :: [string], … }
  ```

  # Examples
  ```nix
  mkNixGroup ["Templates" "nix"] { rust = ["rust"]; dev = ["dev"]; }
  # => {
  #      default = ["Templates" "nix"];
  #      rust    = ["Templates" "nix" "rust"];
  #      dev     = ["Templates" "nix" "dev"];
  #    }
  ```
  */
  mkNixGroup = base: entries:
    {default = base;}
    // mapAttrs (_: suffix: base ++ suffix) entries;

  /**
  Build an image/asset group where all keys extend a shared base directory.

  # Type
  ```
  mkImageGroup :: base :: [string]
              -> { default :: [string], ascii :: [string], … }
  ```
  */
  mkImageGroup = base: {
    default = base;
    ascii = base ++ ["ascii"];
    logo = base ++ ["logo"];
    wallpaper = base ++ ["wallpaper"];
  };

  # ── stems ──────────────────────────────────────────────────────────────────

  /**
  Raw stem segment lists for every well-known location in the project tree.

  Stems are plain lists of strings — pass them to `construct` or `concat`
  as the `stem` argument. They are also the source of truth that `mkPaths`
  resolves into `{ store, local }` pairs.

  # Group shapes
  - `libs`, `pkgs`, `api` — language peers under a shared parent (`mkLangGroup`)
  - `templates`           — functional categories under a nix root (`mkNixGroup`)
  - `images`              — asset sub-directories (`mkImageGroup`)
  - `configuration`, `env` — flat single-key groups for now

  # Examples
  ```nix
  stems.libs.nix              # => ["Libraries" "nix"]
  stems.libs.rust             # => ["Libraries" "rust"]
  stems.pkgs.nix              # => ["Packages" "nix"]
  stems.api.hosts             # => ["API" "nix" "hosts"]
  stems.templates.dev         # => ["Templates" "nix" "dev"]
  stems.images.wallpaper      # => ["Assets" "Images" "wallpaper"]
  stems.configuration.default # => ["Configuration"]
  ```
  */
  stems = let
    bases = {
      libs = ["Libraries"];
      pkgs = ["Packages"];
      api = ["API"];
      templates = ["Templates" "nix"];
      images = ["Assets" "Images"];
      configuration = ["Configuration"];
      env = ["Environment"];
    };
  in {
    default = [];

    libs = mkLangGroup bases.libs {
      nix = "nix";
      shellscript = "shellscript";
      bash = "bash";
      rust = "rust";
      powershell = "powershell";
      python = "python";
      nushell = "nushell";
    };

    pkgs = mkLangGroup bases.pkgs {
      nix = "nix";
      rust = "rust";
    };

    api = mkLangGroup bases.api {
      nix = "nix";
      rust = "rust";
    };

    # api.nix sub-structure — hosts and users live under API/nix
    apiNix = mkNixGroup (bases.api ++ ["nix"]) {
      hosts = ["hosts"];
      users = ["users"];
    };

    templates = mkNixGroup bases.templates {
      rust = ["rust"];
      shellscript = ["shellscript"];
      dev = ["dev"];
      media = ["media"];
    };

    images = mkImageGroup bases.images;

    configuration = {default = bases.configuration;};
    env = {default = bases.env;};
  };

  # ── mkPaths ────────────────────────────────────────────────────────────────

  /**
  Build a fully-resolved path tree for every well-known location in the
  project. Each leaf is a `{ store, local }` attrset produced by `construct`.

  Built-in groups are always present. Callers extend or override them via:

  - `bases` — change the root segment of any group, causing all derived
              keys to re-evaluate from the new base
  - `stems` — patch individual keys, add new keys, or replace a whole group
              (if the incoming group contains a `default` key it takes over
              the full group derivation; otherwise keys are merged deeply)

  # Type
  ```
  mkPaths :: { root  :: path?
             , bases :: { <group> :: [string] }?
             , stems :: { <group> :: { <key> :: [string] } }?
             }
           -> { default :: { store, local }
              , <group> :: { <key> :: { store, local } }
              , …
              }
  ```

  # Arguments
  - `root`  — base directory for all paths; defaults to `src`
  - `bases` — override the root segment of any built-in group; all derived
              keys in that group re-evaluate automatically
  - `stems` — override or extend individual keys, or add new groups; groups
              containing a `default` key replace the full built-in group

  # Examples
  ```nix
  # Default tree — all built-in groups relative to src
  mkPaths {}

  # Re-root all pkgs paths
  mkPaths { bases.pkgs = ["Pkgs"]; }
  # => pkgs.nix.local = "/home/…/dotDots/Pkgs/nix"

  # Add one key to an existing group; siblings are untouched
  mkPaths { stems.images.screenshots = ["Assets" "Images" "screenshots"]; }

  # Replace an entire group — caller owns the full derivation
  mkPaths {
    stems.images = {
      default   = ["Photos"];
      raw       = ["Photos" "raw"];
      processed = ["Photos" "processed"];
    };
  }

  # Add a brand-new group
  mkPaths {
    stems.assets = {
      default = ["Assets"];
      fonts   = ["Assets" "Fonts"];
      icons   = ["Assets" "Icons"];
    };
  }

  # Access
  mkPaths {}.libs.nix.store
  # => "/nix/store/…-dotDots/Libraries/nix"

  mkPaths {}.api.nix.local
  # => "/home/…/dotDots/API/nix"

  mkPaths {}.apiNix.hosts.local
  # => "/home/…/dotDots/API/nix/hosts"

  mkPaths { bases.libs = ["Lib"]; }.libs.rust.local
  # => "/home/…/dotDots/Lib/rust"
  ```
  */
  mkPaths = {
    root ? src,
    bases ? {},
    stems ? {},
  }: let
    # ── Group constructors (with overrideable bases) ─────────────────────────
    defaultBases = {
      libs = ["Libraries"];
      pkgs = ["Packages"];
      api = ["API"];
      templates = ["Templates" "nix"];
      images = ["Assets" "Images"];
      configuration = ["Configuration"];
      env = ["Environment"];
    };

    bases' = defaultBases // bases;

    commonStems = {
      libs = mkLangGroup bases'.libs {
        nix = "nix";
        shellscript = "shellscript";
        bash = "bash";
        rust = "rust";
        powershell = "powershell";
        python = "python";
        nushell = "nushell";
      };

      pkgs = mkLangGroup bases'.pkgs {
        nix = "nix";
        rust = "rust";
      };

      api = mkLangGroup bases'.api {
        nix = "nix";
        rust = "rust";
      };

      apiNix = mkNixGroup (bases'.api ++ ["nix"]) {
        hosts = ["hosts"];
        users = ["users"];
      };

      templates = mkNixGroup bases'.templates {
        rust = ["rust"];
        shellscript = ["shellscript"];
        dev = ["dev"];
        media = ["media"];
      };

      images = mkImageGroup bases'.images;

      configuration = {default = bases'.configuration;};
      env = {default = bases'.env;};
    };

    # ── Merge strategy ───────────────────────────────────────────────────────
    # If the incoming group has a `default` key, the caller owns the full
    # derivation — stop recursing and take it wholesale. Otherwise merge
    # deeply so siblings are preserved.
    stems' =
      recursiveUpdateUntil
      (_path: _lhs: rhs: isAttrs rhs && rhs ? default)
      commonStems
      stems;

    resolveGroup = group:
      mapAttrs (_: stem: construct {inherit root stem;}) group;
  in
    {default = construct {inherit root;};}
    // mapAttrs (_: resolveGroup) stems';
in
  exports
