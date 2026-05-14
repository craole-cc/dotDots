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
    3. String-based rust-overlay channel from configuration.channel

  When a rust-toolchain file is present, the file drives the derivation through
  rust-bin.fromRustupToolchainFile. The module still reads the file to expose
  resolved metadata such as channel, parsed profile, targets, and component flags.

  When no toolchain file is present, the module builds a rust-overlay toolchain
  from rust-bin.${channel}.latest.default.override using resolved extensions and
  targets.
*/
{ lib }:
let
  inherit (lib.attrsets) optionalAttrs mapAttrs recursiveAttrs;
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
      name = "rust";
      cfg =
        let
          set1 = {
            inherit name;
            kind = "toolchain";
            enable = false;
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
          set2 = variant.rust or { };
          set3 = recursiveAttrs { inherit set1 set2; };

          #~@ Cross-variant inputs
          extra = variant.extra or { };
          web = variant.web or { };
          ide = variant.editor or { };
          fmt = variant.fmt or { };

          set4 = {
            #~@ Direct overrides
            channel = if channel != null then channel else set3.channel;
            minimal = if minimal != null then minimal else set3.minimal;
            targets = unique (set3.extraTargets ++ extraTargets);
            extensions = unique (set3.extraExtensions ++ extraExtensions);

            #~@ Cross-variant derived flags
            includeEditor = (ide.enable or false) || set3.includeAnalyzer;
            includeWeb = (web.enable or false) || set3.includeWeb || set3.includeWASM;
            includeExtra = (extra.enable or false) || set3.includeExtra;
            includeFmt = (fmt.enable or true) || set3.includeAnalyzer || set3.includeExtra;

            #~@ Convenience booleans
            nightly = set4.channel == "nightly";
            stable = set4.channel == "stable";
          };
        in
        {
          inherit
            set1
            set2
            set3
            set4
            ;
          final = recursiveAttrs { inherit set3 set4; };
        };
      configuration = cfg.final;
    in
    {
      inherit configuration;
    }
    // optionalAttrs configuration.enable (
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
            channel = if file != null && isNotEmpty (parsed.channel or null) then parsed.channel else configuration.channel;
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
                (if configuration.minimal then profiles.minimal else profiles.default)
                ++ optionals configuration.includeFmt (features.formatting ++ features.linting)
                ++ optionals configuration.includeEditor features.editing
                ++ optionals configuration.includeDocs features.documentation
                ++ configuration.extensions
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
        targets = unique (
          (parsed.targets or [ ]) ++ optionals configuration.includeWeb [ "wasm32-unknown-unknown" ] ++ configuration.targets
        );

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
            }
            // optionalAttrs (configuration.nightly && (!configuration.minimal)) { inherit cargo-careful; }
            // optionalAttrs configuration.includeExtra {
              inherit
                #~@ Watch
                bacon
                cargo-watch
                watchexec
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
            // optionalAttrs configuration.includeWeb { inherit binaryen cargo-leptos leptosfmt; };
            custom = {
              rust =
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
            };
            all = common // custom;
          in
          {
            inherit all common custom;
          };

        binaries =
          let
            common =
              mkBins packages.custom
              // (
                with packages.custom;
                {
                  cargo = "${rust}/bin/cargo";
                  rustc = "${rust}/bin/rustc";
                }
                // optionalAttrs components.hasRustfmt { rustfmt = "${rust}/bin/rustfmt"; }
                // optionalAttrs components.hasClippy { clippy = "${rust}/bin/cargo-clippy"; }
                // optionalAttrs components.hasRustAnalyzer { rust-analyzer = "${rust}/bin/rust-analyzer"; }
              );
            custom = mkBins packages.custom;
            all = common // custom;
          in
          {
            inherit all common custom;
          };

        variables = {
          RUST_SRC_PATH = "${package}/lib/rustlib/src/rust/library";
          RUSTFLAGS = optionalString configuration.nightly "-Z macro-backtrace";
          RUST_BACKTRACE = if configuration.stable then "0" else "full";
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
