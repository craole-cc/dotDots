/**
  packages/rust.nix

  Resolve Rust toolchain, component, target, package, binary, and environment
  metadata from a normalized variant attrset.

  The module derives the Rust setup from these variant namespaces:

    - variant.rust
    - variant.editor
    - variant.web
    - variant.extra
    - variant.fmt

  Direct function arguments may override selected variant values:

    - channel
    - minimal
    - extraTargets
    - extraExtensions

  Toolchain detection order:

    1. project.path + "/rust-toolchain.toml"
    2. project.path + "/rust-toolchain"
    3. String-based rust-overlay channel from cfg.channel

  When a rust-toolchain file is present, the file drives the derivation through
  rust-bin.fromRustupToolchainFile. The module still reads the file to expose
  resolved metadata such as channel, parsed profile, targets, and component flags.

  When no toolchain file is present, the module builds a rust-overlay toolchain
  from rust-bin.${channel}.latest.default.override using resolved extensions and
  targets.
*/
{ lib }:
let
  inherit (lib.attrsets) optionalAttrs mapAttrs updateAttrs;
  inherit (lib.lists) elem optionals unique;
  inherit (lib.meta) project;
  inherit (lib.packages) mkBins;
  inherit (lib.strings) optionalString;
  inherit (lib.trivial)
    fromTOML
    isNotEmpty
    pathExists
    readFile
    ;

  features = {
    minimal = [
      "cargo"
      "rustc"
      "rust-std"
    ];
    linting = [ "clippy" ];
    formatting = [ "rustfmt" ];
    editing = [
      "rust-analyzer"
      "rust-src"
    ];
    documentation = [ "rust-docs" ];
  };

  profiles = mapAttrs (_: unique) (
    with features;
    {
      inherit minimal;
      default = minimal ++ linting;
      standard = minimal ++ linting ++ formatting;
      dev = minimal ++ linting ++ formatting ++ editing;
      docs = minimal ++ documentation;
      full = minimal ++ linting ++ formatting ++ editing ++ documentation;
      ci = minimal ++ linting ++ formatting;
    }
  );
in
{
  /**
    Select a rust-overlay toolchain derivation and related Rust development assets.

    The result is driven primarily by `variant`, with a few direct arguments
    available as local overrides. The function is intended for normalized variant
    attrsets, but supplies defaults for each consumed namespace.

    # Type

    ```nix
    mkRust :: {
      pkgs            :: AttrSet;
      variant         :: AttrSet ? {};
      channel         :: string | null ? null;
      minimal         :: bool | null ? null;
      extraTargets    :: [string] ? [];
      extraExtensions :: [string] ? [];
    } -> {
      cfg        :: AttrSet;

      # Present only when cfg.enable is true:
      channel    :: string;
      package    :: derivation;
      toolchain  :: AttrSet;
      components :: AttrSet;
      targets    :: [string];
      packages   :: AttrSet;
      binaries   :: AttrSet;
      variables  :: AttrSet;

      # Forwarded from package:
      paths      :: AttrSet;
      version    :: string;
      system     :: string;

      # Flattened component metadata:
      extensions      :: [string];
      hasClippy       :: bool;
      hasRustfmt      :: bool;
      hasMiri         :: bool;
      hasLlvmTools    :: bool;
      hasRustAnalyzer :: bool;
      hasSrc          :: bool;
      hasDocs         :: bool;
    }
    Feature groups

    Component groups are defined once and reused by profiles and conditional
    component expansion.

    features = {
      minimal       = ["cargo" "rustc" "rust-std"];
      linting       = ["clippy"];
      formatting    = ["rustfmt"];
      editing       = ["rust-analyzer" "rust-src"];
      documentation = ["rust-docs"];
    };
    Profiles

    Profiles are named component bundles derived from features.
    Each profile is normalized with unique.

    profiles = {
      minimal  = features.minimal;
      default  = features.minimal ++ features.linting;
      standard = features.minimal ++ features.linting ++ features.formatting;
      dev      = features.minimal ++ features.linting ++ features.formatting ++ features.editing;
      docs     = features.minimal ++ features.documentation;
      full     = features.minimal ++ features.linting ++ features.formatting ++ features.editing ++ features.documentation;
      ci       = features.minimal ++ features.linting ++ features.formatting;
    };
    Configuration resolution

    The following variant namespaces are consumed:

    variant.rust
    {
      enable          :: bool;
      channel         :: string;
      minimal         :: bool;
      includeDocs     :: bool;
      includeAnalyzer :: bool;
      includeWeb      :: bool;
      includeLeptos   :: bool;
      includeExtra    :: bool;
      includeWASM     :: bool;
      extraTargets    :: [string];
      extraExtensions :: [string];
    }
    variant.editor
    {
      enable :: bool;
    }

    Enables editor components:

    features.editing

    Equivalent effect may also be requested through:

    variant.rust.includeAnalyzer
    variant.web
    {
      enable :: bool;
    }

    Enables the WASM target and web-related packages.

    Equivalent WASM target expansion may also be requested through:

    variant.rust.includeWeb
    variant.rust.includeWASM
    variant.extra
    {
      enable :: bool;
    }

    Enables the extra Cargo tooling package set.

    Equivalent effect may also be requested through:

    variant.rust.includeExtra
    variant.fmt
    {
      enable :: bool;
    }

    Controls formatting/linting component expansion. Defaults to enabled.

    Direct argument overrides

    The following function arguments override or extend values from variant.rust:

    channel
    minimal
    extraTargets
    extraExtensions

    Resolution rules:

    cfg.channel =
      if channel != null
      then channel
      else variant.rust.channel;

    cfg.minimal =
      if minimal != null
      then minimal
      else variant.rust.minimal;

    cfg.targets =
      unique (variant.rust.extraTargets ++ extraTargets);

    cfg.extensions =
      unique (variant.rust.extraExtensions ++ extraExtensions);

    # Toolchain detection

    Toolchain files are detected from project.path:

    project.path + "/rust-toolchain.toml"
    project.path + "/rust-toolchain"

    If either file exists:

    toolchain.source = "file";

    Otherwise:

    toolchain.source = "string";

    For file-based toolchains, the TOML payload is read from:

    (fromTOML (readFile file)).toolchain or {}

    The exposed channel is resolved as:

    if file != null && isNotEmpty (parsed.channel or null)
    then parsed.channel
    else cfg.channel
    Component resolution
    File-based toolchain

    When a rust-toolchain file exists:

    profile  = parsed.profile or "default";
    base     = profiles.${profile} or profiles.default;
    explicit = parsed.components or [];

    extensions = unique (base ++ explicit);

    The package derivation is created with:

    rust-bin.fromRustupToolchainFile toolchain.file

    Important: for file-based toolchains, the file controls the derivation.
    The module still computes extensions so that components.has* metadata
    reflects the selected profile, explicit file components, and extra extensions.

    String-based toolchain

    When no rust-toolchain file exists:

    extensions =
      (
        if cfg.minimal
        then profiles.minimal
        else profiles.default
      )
      ++ optionals cfg.includeFmt (features.formatting ++ features.linting)
      ++ optionals cfg.includeEditor features.editing
      ++ optionals cfg.includeDocs features.documentation
      ++ cfg.extensions;

    The package derivation is created with:

    rust-bin.${toolchain.channel}.latest.default.override {
      inherit (components) extensions;
      inherit targets;
    }
    Component metadata

    The resolved extension list is exposed as:

    components.extensions
    extensions

    The following booleans are derived from that list:

    hasClippy       = elem "clippy" extensions;
    hasRustfmt      = elem "rustfmt" extensions;
    hasMiri         = elem "miri" extensions;
    hasLlvmTools    = elem "llvm-tools" extensions;
    hasRustAnalyzer = elem "rust-analyzer" extensions;
    hasSrc          = elem "rust-src" extensions;
    hasDocs         = elem "rust-docs" extensions;
    Target resolution

    Targets are resolved as:

    targets = unique (
      (parsed.targets or [])
      ++ optionals cfg.includeWeb ["wasm32-unknown-unknown"]
      ++ cfg.targets
    );

    cfg.includeWeb is true when any of the following are enabled:

    variant.web.enable
    variant.rust.includeWeb
    variant.rust.includeWASM
    Package groups

    The returned packages attrset has this shape:

    packages = {
      common :: AttrSet;
      custom :: AttrSet;
      all    :: AttrSet;
    };

    packages.common always includes:

    gcc
    rust = [package]

    When using nightly and not minimal, it also includes:

    cargo-careful

    When cfg.includeExtra is true, it includes additional Cargo tooling:

    bacon
    cargo-watch
    cargo-edit
    cargo-outdated
    cargo-audit
    cargo-deny
    cargo-flamegraph
    cargo-bloat
    cargo-expand
    cargo-nextest
    cargo-tarpaulin
    cargo-make

    When cfg.includeWeb is true, it includes:

    binaryen
    cargo-leptos
    leptosfmt

    packages.custom is currently empty and reserved for extension.

    Binary groups

    The returned binaries attrset mirrors the package groups after processing
    with mkBins:

    binaries = {
      common :: AttrSet;
      custom :: AttrSet;
      all    :: AttrSet;
    };
    Environment variables

    The returned variables attrset contains:

    RUST_SRC_PATH
    RUSTFLAGS
    RUST_BACKTRACE
    RUST_LOG
    CARGO_INCREMENTAL
    RUST_CHANNEL
    RUST_TOOLCHAIN_FILE

    Nightly enables:

    RUSTFLAGS = "-Z macro-backtrace";
    RUST_BACKTRACE = "full";

    Stable uses:

    RUST_BACKTRACE = "0";
    Examples
    # Default variant-driven Rust setup.
    mkRust {
      inherit pkgs variant;
    }

    # Stable string-based toolchain.
    mkRust {
      inherit pkgs variant;
      channel = "stable";
    }

    # Minimal string-based toolchain.
    mkRust {
      inherit pkgs variant;
      minimal = true;
    }

    # Add explicit targets and extensions without modifying the variant.
    mkRust {
      inherit pkgs variant;
      extraTargets = ["wasm32-unknown-unknown"];
      extraExtensions = ["miri" "llvm-tools"];
    }

    # Variant-driven web setup.
    mkRust {
      inherit pkgs;
      variant = normalizeVariant {
        web.enable = true;
      };
    }

    # Variant-driven editor setup.
    mkRust {
      inherit pkgs;
      variant = normalizeVariant {
        editor.enable = true;
      };
    }

    # Extra Cargo tooling.
    mkRust {
      inherit pkgs;
      variant = normalizeVariant {
        extra.enable = true;
      };
    }
  */
  mkRust =
    {
      pkgs,
      variant ? { },
      channel ? null,
      minimal ? null,
      extraTargets ? [ ],
      extraExtensions ? [ ],
    }:
    let
      #╔═══════════════════════════════════════════════════════════╗
      #║ Variant Configuration                                     ║
      #╚═══════════════════════════════════════════════════════════╝
      cfg =
        let
          rust = updateAttrs {
            name = "rust";
            value = variant;
            default = {
              kind = "toolchain";
              name = "rust";
              enable = true;
              channel = "nightly";
              minimal = false;
              includeDocs = false;
              includeAnalyzer = false;
              includeWeb = false;
              includeLeptos = false;
              includeExtra = false;
              includeWASM = false;
              extraTargets = [ ];
              extraExtensions = [ ];
            };
          };
          extra = updateAttrs {
            name = "extra";
            value = variant;
            default = {
              kind = "core";
              name = "extra";
              enable = false;
            };
          };
          web = updateAttrs {
            name = "web";
            value = variant;
            default = {
              kind = "integration";
              name = "web";
              enable = false;
            };
          };
          ide = updateAttrs {
            name = "editor";
            value = variant;
            default = {
              kind = "workflow";
              name = "editor";
              enable = false;
            };
          };
          fmt = updateAttrs {
            name = "fmt";
            value = variant;
            default = {
              kind = "workflow";
              name = "formatter";
              enable = true;
            };
          };
        in
        {
          inherit (rust)
            kind
            name
            enable
            includeLeptos
            ;
          minimal = if minimal != null then minimal else rust.minimal;
          channel = if channel != null then channel else rust.channel;
          nightly = cfg.channel == "nightly";
          stable = cfg.channel == "stable";
          targets = unique (rust.extraTargets ++ extraTargets);
          extensions = unique (rust.extraExtensions ++ extraExtensions);
          includeEditor = ide.enable || rust.includeAnalyzer;
          includeWeb = web.enable || rust.includeWeb || rust.includeWASM;
          inherit (rust) includeDocs;
          includeExtra = extra.enable || rust.includeExtra;
          includeFmt = fmt.enable || cfg.includeEditor || rust.includeExtra;
        };
    in
    {
      configuration = cfg;
    }
    // optionalAttrs cfg.enable (
      let
        #╔═══════════════════════════════════════════════════════════╗
        #║ Toolchain Detection                                       ║
        #╚═══════════════════════════════════════════════════════════╝
        toolchain =
          let
            root = project.path;
            rootToml = root + "/rust-toolchain.toml";
            rootBare = root + "/rust-toolchain";
            file =
              if pathExists rootToml then
                rootToml
              else if pathExists rootBare then
                rootBare
              else
                null;

            source = if file != null then "file" else "string";

            parsed = optionalAttrs (file != null) ((fromTOML (readFile file)).toolchain or { });
          in
          {
            inherit file source parsed;
            channel = if file != null && isNotEmpty (parsed.channel or null) then parsed.channel else cfg.channel;
          };

        inherit (toolchain) file parsed;

        #╔═══════════════════════════════════════════════════════════╗
        #║ Components Resolution                                     ║
        #╚═══════════════════════════════════════════════════════════╝
        components =
          let
            extensions = unique (
              if file != null then
                let
                  profile = parsed.profile or "default";
                  base = profiles.${profile} or profiles.default;
                  explicit = parsed.components or [ ];
                in
                base ++ explicit
              else
                (if cfg.minimal then profiles.minimal else profiles.default)
                ++ optionals cfg.includeFmt (features.formatting ++ features.linting)
                ++ optionals cfg.includeEditor features.editing
                ++ optionals cfg.includeDocs features.documentation
                ++ cfg.extensions
            );
          in
          {
            inherit extensions;
            hasClippy = elem "clippy" extensions;
            hasRustfmt = elem "rustfmt" extensions;
            hasMiri = elem "miri" extensions;
            hasLlvmTools = elem "llvm-tools" extensions;
            hasRustAnalyzer = elem "rust-analyzer" extensions;
            hasSrc = elem "rust-src" extensions;
            hasDocs = elem "rust-docs" extensions;
          };

        #╔═══════════════════════════════════════════════════════════╗
        #║ Targets Resolution                                        ║
        #╚═══════════════════════════════════════════════════════════╝
        targets = unique ((parsed.targets or [ ]) ++ optionals cfg.includeWeb [ "wasm32-unknown-unknown" ] ++ cfg.targets);

        #╔═══════════════════════════════════════════════════════════╗
        #║ Packages                                                  ║
        #╚═══════════════════════════════════════════════════════════╝
        package =
          let
            rust-bin = pkgs.rust-bin or (throw "lib.packages.mkRust: pkgs.rust-bin not found — is the rust-overlay applied?");
          in
          if file != null then
            rust-bin.fromRustupToolchainFile toolchain.file
          else
            rust-bin.${toolchain.channel}.latest.default.override {
              inherit (components) extensions;
              inherit targets;
            };

        packages =
          with pkgs;
          let
            common = {
              inherit gcc;
              rust = [ package ];
            }
            // optionalAttrs (cfg.nightly && (!cfg.minimal)) { inherit cargo-careful; }
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
            // optionalAttrs cfg.includeWeb { inherit binaryen cargo-leptos leptosfmt; };
            custom = { };
            all = common // custom;
          in
          {
            inherit all common custom;
          };

        binaries =
          let
            common = mkBins packages.common;
            custom = mkBins packages.custom;
            all = common // custom;
          in
          {
            inherit all common custom;
          };

        variables = {
          RUST_SRC_PATH = "${package}/lib/rustlib/src/rust/library";
          RUSTFLAGS = optionalString cfg.nightly "-Z macro-backtrace";
          RUST_BACKTRACE = if cfg.stable then "0" else "full";
          RUST_LOG = "info";
          CARGO_INCREMENTAL = "1";
          RUST_CHANNEL = toolchain.channel;
          RUST_TOOLCHAIN_FILE = if file != null then toString file else "<channel>";
        };
      in
      {
        inherit
          binaries
          components
          package
          packages
          targets
          toolchain
          variables
          ;
        inherit (package) paths version system;
        inherit (toolchain) channel;
      }
      // components
    );
}
