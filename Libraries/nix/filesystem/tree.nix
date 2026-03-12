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
    internal = {inherit stems mkTree wallman;};
    external = {mkProjectTree = mkTree;};
  };

  # ── Group constructors ─────────────────────────────────────────────────────

  /**
  Build a multi-language group where sibling languages share a common parent
  directory. Each language is a peer — none derives from another.

  `default` always points to `nix` as the project-primary language.

  Used for: `Libraries`, `Packages`, `API`, `Templates` — all follow the
  pattern `<parent>/<language>/`.

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
  #      default = ["Libraries" "nix"];
  #      nix     = ["Libraries" "nix"];
  #      rust    = ["Libraries" "rust"];
  #    }
  ```
  */
  mkLangGroup = parent: langs:
    {default = parent ++ ["nix"];}
    // mapAttrs (_: lang: parent ++ [lang]) langs;

  # ── Shared default bases ───────────────────────────────────────────────────
  #
  # Defined once here and shared between `stems` and `mkPaths` so they can
  # never drift out of sync. `mkPaths` overrides these via its `bases` arg.

  defaultBases = {
    api = ["API"];
    cfg = ["Configuration"];
    env = ["Environment"];
    kit = ["Templates"];
    lib = ["Libraries"];
    pkg = ["Packages"];
    res = ["Assets"];
  };

  # ── mkGroup ────────────────────────────────────────────────────────────────
  #
  # Build all group stems from a resolved `bases` attrset. Extracted so both
  # `stems` and `mkPaths` use exactly the same construction logic and can
  # never diverge.

  mkGroup = bases: {
    # api: language peers + nix sub-structure (hosts, users) as flat siblings
    # Access: api.nix, api.rust, api.hosts, api.users
    api = let
      base = bases.api ++ ["nix"];
    in
      mkLangGroup bases.api {
        nix = "nix";
        rs = "rust";
      }
      // {
        hosts = base ++ ["hosts"];
        users = base ++ ["users"];
      };

    cfg = {default = bases.cfg;};

    env = {default = bases.env;};

    # kit: language peers + nix template types as flat siblings
    # Access: templates.nix, templates.rust, templates.shellscript,
    #         templates.common, templates.dev, templates.media
    kit = let
      base = bases.kit ++ ["nix"];
    in
      mkLangGroup bases.kit {
        nix = "nix";
        rs = "rust";
        sh = "shellscript";
      }
      // {
        common = base ++ ["common"];
        dev = base ++ ["dev"];
        media = base ++ ["media"];
      };

    lib = mkLangGroup bases.lib {
      bash = "bash";
      nix = "nix";
      nu = "nushell";
      sh = "shellscript";
      pwsh = "powershell";
      py = "python";
      rs = "rust";
    };

    # pkg: language peers + nix sub-structure as flat siblings
    # Access: pkg.nix, pkg.rust, pkg.global, pkg.core, pkg.home, …
    pkg = let
      base = bases.pkg ++ ["nix"];
      global = base ++ ["global"];
      core = base ++ ["core"];
      home = base ++ ["home"];
      overlays = base ++ ["overlays"];
      plugins = base ++ ["plugins"];
    in
      mkLangGroup bases.pkg {
        nix = "nix";
        rs = "rust";
      }
      // {inherit global core home overlays plugins;};

    # res: top-level Assets/ with typed sub-dirs as flat siblings.
    # Images sub-dirs (ascii, logo, wallpaper) also flat for uniform depth.
    # Access: assets.default, assets.images, assets.fonts, assets.icons,
    #         assets.ascii, assets.logo, assets.wallpaper
    res = let
      images = bases.res ++ ["Images"];
      default = bases.res;
      fonts = bases.res ++ ["Fonts"];
      icons = bases.res ++ ["Icons"];
      ascii = images ++ ["ascii"];
      logo = images ++ ["logo"];
      wallpaper = images ++ ["wallpaper"];
    in {inherit default images fonts icons ascii logo wallpaper;};
  };

  # ── stems ──────────────────────────────────────────────────────────────────

  /**
  Raw stem segment lists for every well-known location in the project tree.

  Stems are plain lists of strings — pass them to `construct` or `concat`
  as the `stem` argument. They are the source of truth that `mkPaths`
  resolves into `{ store, local }` pairs.

  # Group shapes
  - `lib`    — language peers: `Libraries/<lang>/`
  - `pkg`    — language peers + nix sub-dirs: `Packages/<lang>/`
  - `api`    — language peers + nix sub-dirs: `API/<lang>/`
  - `kit`    — language peers + nix template types: `Templates/<lang>/`
  - `res`    — `Assets/` with typed sub-dirs as flat siblings
  - `cfg`    — flat single-key group
  - `env`    — flat single-key group

  # Examples
  ```nix
  stems.lib.nix         # => ["Libraries" "nix"]
  stems.lib.rust        # => ["Libraries" "rust"]
  stems.pkg.nix         # => ["Packages" "nix"]
  stems.pkg.overlays    # => ["Packages" "nix" "overlays"]
  stems.api.nix         # => ["API" "nix"]
  stems.api.hosts       # => ["API" "nix" "hosts"]
  stems.kit.nix         # => ["Templates" "nix"]
  stems.kit.rust        # => ["Templates" "rust"]
  stems.kit.common      # => ["Templates" "nix" "common"]
  stems.kit.dev         # => ["Templates" "nix" "dev"]
  stems.res.default     # => ["Assets"]
  stems.res.images      # => ["Assets" "Images"]
  stems.res.fonts       # => ["Assets" "Fonts"]
  stems.res.icons       # => ["Assets" "Icons"]
  stems.res.wallpaper   # => ["Assets" "Images" "wallpaper"]
  stems.cfg.default     # => ["Configuration"]
  stems.env.default     # => ["Environment"]
  ```
  */
  stems = {default = [];} // mkGroup defaultBases;

  # wallman.sh lives alongside this file in Libraries/nix/filesystem/.
  # Exported as a path value so consumers (e.g. modules/home/paths.nix) can
  # reference it via _.filesystem.tree.wallman without a fragile relative path.
  wallman = ./wallman.sh;

  # ── mkPaths ────────────────────────────────────────────────────────────────

  /**
  Build a fully-resolved path tree for every well-known location in the
  project. Each leaf is a `{ store, local }` attrset produced by `construct`.

  Built-in groups are always present. Callers extend or override them via:

  - `bases` — change the root segment of any group, re-deriving all keys
  - `stems` — patch individual keys, add new keys, or replace a whole group
              (a group with a `default` key takes over the full derivation;
              otherwise keys merge deeply, preserving siblings)

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
              keys re-evaluate automatically
  - `stems` — override/extend individual keys, or add new groups; groups
              with a `default` key replace the full built-in group

  # Examples
  ```nix
  mkPaths {}.lib.nix.store         # => "/nix/store/…-dotDots/Libraries/nix"
  mkPaths {}.api.hosts.local       # => "/home/…/dotDots/API/nix/hosts"
  mkPaths {}.pkg.overlays.store    # => "/nix/store/…-dotDots/Packages/nix/overlays"
  mkPaths {}.assets.fonts.local    # => "/home/…/dotDots/Assets/Fonts"

  mkPaths { bases.lib = ["Lib"]; }.lib.rust.local
  # => "/home/…/dotDots/Lib/rust"

  mkPaths { stems.assets.screenshots = ["Assets" "Images" "screenshots"]; }
  # adds screenshots alongside existing siblings
  ```
  */
  mkTree = {
    root ? src,
    bases ? {},
    stems ? {},
  }: let
    bases' = defaultBases // bases;
    commonStems = mkGroup bases';

    # Stop recursing when the incoming group has a `default` key — the caller
    # owns the full derivation. Otherwise merge deeply so siblings survive.
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
  exports.internal // {_rootAliases = exports.external;}
