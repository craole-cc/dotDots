/**
packages/rust.nix

Resolve a Rust toolchain derivation from a normalized variant attrset.

Reads variant.rust, variant.web, and variant.editor to determine components
and targets — no duplicate flags needed at the call-site.

Toolchain file resolution order:
  1. paths.flake + "/rust-toolchain.toml"
  2. paths.flake + "/rust-toolchain"
  3. String-based channel from variant.rust.channel (default: "nightly")
*/
{
  lib,
  paths,
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem optionals unique;
  inherit (lib.trivial) fromTOML isNotEmpty pathExists readFile;

  # ---------------------------------------------------------------------------
  # Component profiles
  #
  # Non-overlapping sets composed additively.  No set is a superset of another
  # except default ⊃ minimal, so combining them never duplicates entries
  # (extraExtensions is deduplicated at call-site via `unique`).
  #
  # Reference: https://rust-lang.github.io/rustup/concepts/profiles.html
  # ---------------------------------------------------------------------------
  profiles = let
    minimal = ["cargo" "rustc" "rust-std"];
    default = minimal ++ ["clippy" "rust-docs" "rustfmt"];
    ide = ["rust-analyzer" "rust-src"];
    docs = ["rust-docs"];
  in {inherit minimal default ide docs;};

  # ---------------------------------------------------------------------------
  # mkRust
  # ---------------------------------------------------------------------------

  /**
  Select a rust-overlay toolchain derivation driven entirely by `variant`.

  # Type
  ```
  mkRust :: {
    pkgs    :: AttrSet;   #? must carry pkgs.rust-bin from rust-overlay
    variant :: AttrSet;   #? normalized variant — reads .rust .web .editor
    paths   :: AttrSet;   #? lib paths — uses paths.flake for file detection
  } -> {
    kind            :: string;      #? always "rust"
    channel         :: string;      #? resolved channel
    package         :: derivation;  #? rust-overlay toolchain derivation
    toolchain       :: AttrSet;     #? { file, source, parsed, channel }
    components      :: AttrSet;     #? { extensions, has* }
    targets         :: [string];

    #? Flat component aliases:
    extensions      :: [string];
    hasClippy       :: bool;
    hasRustfmt      :: bool;
    hasMiri         :: bool;
    hasLlvmTools    :: bool;
    hasRustAnalyzer :: bool;
    hasSrc          :: bool;
    hasDocs         :: bool;

    #? Forwarded from the derivation:
    paths           :: AttrSet;
    version         :: string;
    system          :: string;
  }
  ```

  # Component resolution

  ## File-based (toolchain.file != null)
  TOML `profile` (default: "default") selects the base component set.
  File `components` and `variant.rust.extraExtensions` are merged in and
  deduplicated.  The derivation is built with `fromRustupToolchainFile`.
  `extraExtensions` and `extraTargets` are reflected in `has*` / `targets`
  but are NOT forwarded to the derivation (the file drives it).

  ## String-based (toolchain.file == null)
  ```
  (variant.rust.minimal ? profiles.minimal : profiles.default)
  ++ (variant.rust.includeDocs   ? profiles.docs : [])
  ++ (variant.editor.enable      ? profiles.ide  : [])
  ++ variant.rust.extraExtensions
  ```
  Derivation built with `rust.${channel}.latest.default.override`.

  # Variant flags consumed
  - variant.rust.channel          → toolchain channel (string-based path)
  - variant.rust.minimal          → minimal vs default profile
  - variant.rust.includeDocs      → append rust-docs
  - variant.rust.extraTargets     → additional targets
  - variant.rust.extraExtensions  → additional components
  - variant.web.enable            → appends wasm32-unknown-unknown target
  - variant.editor.enable         → appends rust-analyzer + rust-src (ide profile)

  # Examples
  ```nix
  # Typical dev shell — nightly + ide + wasm if web enabled
  mkRust { inherit pkgs variant paths; }

  # CI shell — minimal, no editor tools
  mkRust {
    inherit pkgs paths;
    variant = normalizeVariant { rust.minimal = true; };
  }

  # Stable channel via variant
  mkRust {
    inherit pkgs paths;
    variant = normalizeVariant { rust = { channel = "stable"; }; };
  }
  ```
  */
  mkRust = {
    pkgs,
    paths,
    variant ? {
      rust = {
        channel = "nightly";
        minimal = false;
        includeDocs = false;
        extraTargets = [];
        extraExtensions = [];
      };
      web = {enable = false;};
      editor = {enable = false;};
    },
  }: let
    inherit (variant) rust web editor;
    inherit (rust) channel minimal includeDocs extraTargets extraExtensions;

    # -------------------------------------------------------------------------
    # Toolchain file detection
    # -------------------------------------------------------------------------
    toolchain = let
      rootToml = paths.flake + "/rust-toolchain.toml";
      rootBare = paths.flake + "/rust-toolchain";
      file =
        if pathExists rootToml
        then rootToml
        else if pathExists rootBare
        then rootBare
        else null;
    in {
      inherit file;

      source =
        if file != null
        then "file"
        else "string";

      parsed =
        if file != null
        then (fromTOML (readFile file)).toolchain or {}
        else {};

      channel =
        if file != null && isNotEmpty (toolchain.parsed.channel or null)
        then toolchain.parsed.channel
        else channel;
    };

    inherit (toolchain) parsed;

    # -------------------------------------------------------------------------
    # Component resolution
    # -------------------------------------------------------------------------
    components = let
      extensions =
        if toolchain.file != null
        then let
          profile = parsed.profile or "default";
          base = profiles.${profile} or profiles.default;
          explicit = parsed.components or [];
        in
          unique (base ++ explicit ++ extraExtensions)
        else
          (
            if minimal
            then profiles.minimal
            else profiles.default
          )
          ++ optionals includeDocs profiles.docs
          ++ optionals editor.enable profiles.ide
          ++ extraExtensions;
    in {
      inherit extensions;
      hasClippy = elem "clippy" extensions;
      hasRustfmt = elem "rustfmt" extensions;
      hasMiri = elem "miri" extensions;
      hasLlvmTools = elem "llvm-tools" extensions;
      hasRustAnalyzer = elem "rust-analyzer" extensions;
      hasSrc = elem "rust-src" extensions;
      hasDocs = elem "rust-docs" extensions;
    };

    # -------------------------------------------------------------------------
    # Target resolution
    # -------------------------------------------------------------------------
    targets = unique (
      (parsed.targets or [])
      ++ optionals web.enable ["wasm32-unknown-unknown"]
      ++ extraTargets
    );

    # -------------------------------------------------------------------------
    # Derivation
    # -------------------------------------------------------------------------
    package = let
      rust-bin =
        pkgs.rust-bin
        or (throw "lib.packages.mkRust: pkgs.rust-bin not found — is the rust-overlay applied?");
    in
      if toolchain.file != null
      then rust-bin.fromRustupToolchainFile toolchain.file
      else
        rust-bin.${toolchain.channel}.latest.default.override {
          inherit (components) extensions;
          inherit targets;
        };
  in
    {
      kind = "rust";
      inherit toolchain package components targets;
      inherit (package) paths version system;
      inherit (toolchain) channel;
    }
    // components;
in {inherit mkRust profiles;}
