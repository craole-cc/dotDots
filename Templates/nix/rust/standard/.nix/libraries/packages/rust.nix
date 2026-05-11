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
{lib}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.lists) elem optionals unique;
  inherit (lib.meta.project) root;
  inherit (lib.packages) mkBins;
  inherit (lib.strings) optionalString;
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
  rustProfiles = let
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
    variant ? {
      rust = {
        channel = "nightly";
        extraExtensions = [];
        extraTargets = [];
        includeAnalyzer = false;
        includeDocs = false;
        includeExtra = false;
        includeWeb = false;
        minimal = false;
      };
      extra.enable = false;
      web.enable = false;
      editor.enable = false;
    },
    channel ? null,
    minimal ? null,
    extraTargets ? [],
    extraExtensions ? [],
  }: let
    inherit (variant) rust extra web editor;
    cfg = {
      channel =
        if channel != null
        then channel
        else rust.channel;
      minimal = minimal != null || rust.minimal;
      extensions = unique (rust.extraExtensions ++ extraExtensions);
      includeAnalyzer = editor.enable || rust.includeAnalyzer;
      includeWeb = web.enable || rust.includeWeb;
      includeDocs = web.enable || rust.includeDocs;
      includeExtra = extra.enable || rust.includeExtra;
      nightly = cfg.channel == "nightly";
    };

    # Toolchain file detection

    toolchain = let
      rootToml = root + "/rust-toolchain.toml";
      rootBare = root + "/rust-toolchain";
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
        else cfg.channel;
    };

    inherit (toolchain) parsed;

    # Component resolution

    components = let
      extensions =
        if toolchain.file != null
        then let
          profile = parsed.profile or "default";
          base = rustProfiles.${profile} or rustProfiles.default;
          explicit = parsed.components or [];
        in
          unique (base ++ explicit ++ cfg.extensions)
        else
          (
            if cfg.minimal
            then rustProfiles.minimal
            else rustProfiles.default
          )
          ++ optionals cfg.includeDocs rustProfiles.docs
          ++ optionals cfg.includeAnalyzer rustProfiles.ide
          ++ cfg.extensions;
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

    # Target resolution

    targets = unique (
      (parsed.targets or [])
      ++ optionals (web.enable or cfg.includeWASM) ["wasm32-unknown-unknown"]
      ++ (cfg.extraTargets or extraTargets)
    );

    # Derivation

    package = let
      rust-bin =
        pkgs.rust-bin
        or (
          throw "lib.packages.mkRust: pkgs.rust-bin not found — is the rust-overlay applied?"
        );
    in
      if toolchain.file != null
      then rust-bin.fromRustupToolchainFile toolchain.file
      else
        rust-bin.${toolchain.channel}.latest.default.override {
          inherit (components) extensions;
          inherit targets;
        };

    packages = with pkgs;
        {inherit gcc;}
        // optionalAttrs stdenv.isDarwin {inherit libiconv;}
        // optionalAttrs (cfg.nightly && (!cfg.minimal)) {inherit cargo-careful;}
        // optionalAttrs cfg.includeExtra {
          inherit
            #~@ Watch
            bacon
            cargo-watch
            #~@ Dependencies & Security
            cargo-edit
            cargo-outdated
            cargo-audit
            cargo-deny
            #~@ Performance & Analysis
            cargo-flamegraph
            cargo-bloat
            cargo-expand
            #~@ Testing & Quality
            cargo-nextest
            cargo-tarpaulin
            #~@ Formatting
            cargo-make
            ;
        }
        // optionalAttrs cfg.includeWeb {
          inherit
            binaryen
            cargo-leptos
            leptosfmt
            ;
        };

    binaries = {
      packages = mkBins packages;
      scripts = mkBins scripts;
      all = binaries.packages // binaries.scripts;
    };

    scripts = {};

    all = [package] ++ attrValues packages ++ attrValues scripts;
  in
    {
      kind = "rust";
      inherit all toolchain package packages binaries scripts components targets;
      inherit (package) paths version system;
      inherit (toolchain) channel;
      env = {
        RUST_SRC_PATH = "${package}/lib/rustlib/src/rust/library";
        RUSTFLAGS = optionalString cfg.nightly "-Z macro-backtrace";
        RUST_BACKTRACE =
          if cfg.channel == "stable"
          then "0"
          else "full";
        RUST_LOG = "info";
        CARGO_INCREMENTAL = "1";
        RUST_CHANNEL = toolchain.channel;
        RUST_TOOLCHAIN_FILE =
          if toolchain.file != null
          then toString toolchain.file
          else "<channel>";
      };
    }
    // components;
in {inherit mkRust rustProfiles;}
