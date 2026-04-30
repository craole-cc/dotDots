{lib}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) elem optionals unique;
  inherit (lib.trivial) fromTOML isNotEmpty pathExists readFile;

  /**
  Non-overlapping component sets used to compose a toolchain.

  `minimal` and `default` are base profiles; `ide` and `docs` are additive
  feature sets appended on top.  Because they do not overlap, combining them
  never produces duplicate entries (except when `extraExtensions` is involved,
  which is deduplicated at call-site).

  - `minimal` → cargo, rustc, rust-std
  - `default` → minimal + clippy, rust-docs, rustfmt  (lint / CI baseline)
  - `ide`     → rust-analyzer, rust-src               (editor / LSP — additive)
  - `docs`    → rust-docs                             (offline book — additive)

  Note: `rust-docs` appears in both `default` and `docs`.  On the string-based
  path `includeDocs` is therefore only meaningful when `minimal = true`.

  Reference: https://rust-lang.github.io/rustup/concepts/profiles.html
  */
  profiles = let
    minimal = ["cargo" "rustc" "rust-std"];
    default = minimal ++ ["clippy" "rust-docs" "rustfmt"];
    ide = ["rust-analyzer" "rust-src"];
    docs = ["rust-docs"];
  in {inherit minimal default ide docs;};

  /**
  Select a rust-overlay toolchain derivation.

  Resolves a Rust toolchain from either a `rust-toolchain.toml` file (auto-
  detected or explicit) or a set of inline parameters.  Returns a rich attrset
  that includes the derivation, resolved component flags, and target list so
  that downstream shell / CI definitions can conditionally enable or skip steps
  depending on what is actually installed.

  # Type
  ```
  mkRust :: {
    pkgs            :: AttrSet;     #? must include rust-bin from rust-overlay
    channel         ? string;       #? "stable" | "beta" | "nightly" | "nightly-YYYY-MM-DD"
                                    # default: "nightly"
    minimal         ? bool;         #? use minimal profile — no clippy / rustfmt
                                    # default: false
    toolchainFile   ? path;         #? explicit path to rust-toolchain.toml
                                    # default: auto-detects ../../rust-toolchain.toml,
                                    #          then ../../templates/rust-toolchain.toml
    includeEditor   ? bool;         #? append ide components (rust-analyzer, rust-src)
                                    # default: true
    includeDocs     ? bool;         #? append docs component (rust-docs)
                                    #? only meaningful when minimal = true
                                    # default: false
    includeWeb      ? bool;         #? append wasm32-unknown-unknown target
                                    # default: false
    extraTargets    ? [string];     #? additional targets appended after all others
                                    # default: []
    extraExtensions ? [string];     #? additional components appended after all others
                                    # default: []
  } -> {
    kind            :: string;      #? always "rust"
    channel         :: string;      #? resolved channel string
    package         :: derivation;  #? the rust-overlay toolchain derivation
    toolchain       :: AttrSet;     #? { file, source, parsed, channel }
    components      :: AttrSet;     #? { extensions :: [string], has* :: bool }
    targets         :: [string];    #? fully resolved target list

    #? Flat aliases from components (also accessible as components.X):
    extensions      :: [string];
    hasClippy       :: bool;        #? cargo clippy
    hasRustfmt      :: bool;        #? cargo fmt
    hasMiri         :: bool;        #? cargo miri test
    hasLlvmTools    :: bool;        #? cargo-llvm-cov, cargo-binutils
    hasRustAnalyzer :: bool;        #? LSP server
    hasSrc          :: bool;        #? rust-src — required for rust-analyzer std nav
    hasDocs         :: bool;        #? rust-docs — local rustup doc

    #? Forwarded from the derivation:
    paths           :: AttrSet;
    version         :: string;
    system          :: string;
  }
  ```

  # Component resolution

  ## File-based path (`toolchain.file != null`)
  The TOML `profile` field (default: `"default"`) selects a base component set
  from `profiles`, which is then merged with any `components` declared in the
  file and with `extraExtensions`.  The result is deduplicated via `unique`.
  The derivation is built with `fromRustupToolchainFile`; `extraExtensions` and
  `extraTargets` are reflected in the `has*` flags and `targets` attrset fields
  but are **not** forwarded to the derivation itself.

  ## String-based path (`toolchain.file == null`)
  Components are composed from non-overlapping sets:
  ```
  (minimal ? profiles.minimal : profiles.default)
  ++ (includeDocs   ? profiles.docs : [])
  ++ (includeEditor ? profiles.ide  : [])
  ++ extraExtensions
  ```
  The derivation is built with `rust.${channel}.latest.default.override`.

  # Examples
  ```nix
  #? Nightly toolchain with default + ide components (the typical dev setup)
  mkRust { inherit pkgs; }

  #? Stable channel, no editor components
  mkRust { inherit pkgs; channel = "stable"; includeEditor = false; }

  #? CI: minimal baseline — hasClippy = false, hasRustfmt = false
  mkRust { inherit pkgs; minimal = true; }

  #? Toolchain file drives the profile and components
  mkRust { inherit pkgs; toolchainFile = ./rust-toolchain.toml; }

  #? Toolchain file + WASM target + extra component
  mkRust {
    inherit pkgs;
    toolchainFile   = ./rust-toolchain.toml;
    includeWeb      = true;
    extraExtensions = ["miri"];
  }
  ```

  # Conditional lint example
  ```nix
  inherit (rust) package channel hasRustfmt hasClippy;
   cmd =
      {
        lint = lib.strings.concatStringsSep " && " (
          [ cmd.check ]
          ++ lib.lists.optional rust.hasRustfmt cmd.fmtrs
          ++ lib.lists.optional rust.hasClippy  cmd.clippy
        );
      };
  ```
  */
  mkRust = {
    pkgs,
    channel ? null,
    minimal ? false,
    toolchainFile ? null,
    includeEditor ? true,
    includeDocs ? false,
    includeWeb ? false,
    extraTargets ? [],
    extraExtensions ? [],
  }: let
    toolchain = {
      file = let
        root = ../../rust-toolchain.toml;
        template = ../../templates/rust-toolchain.toml;
      in
        if toolchainFile != null && pathExists toolchainFile
        then toolchainFile
        else if pathExists root
        then root
        else if pathExists template
        then template
        else null;

      source =
        if isNotEmpty toolchain.file
        then "file"
        else "string";

      parsed =
        optionalAttrs (isNotEmpty toolchain.file)
        (fromTOML (readFile toolchain.file)).toolchain;

      channel =
        if isNotEmpty toolchain.parsed && toolchain.parsed ? channel
        then toolchain.parsed.channel
        else if isNotEmpty channel
        then channel
        else "nightly";
    };
    inherit (toolchain) parsed;

    components = let
      extensions =
        if isNotEmpty parsed
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
          ++ optionals includeEditor profiles.ide
          ++ extraExtensions;
    in {
      inherit extensions;
      hasClippy = elem "clippy" extensions; # cargo clippy
      hasRustfmt = elem "rustfmt" extensions; # cargo fmt
      hasMiri = elem "miri" extensions; # cargo miri test
      hasLlvmTools = elem "llvm-tools" extensions; # cargo-llvm-cov, cargo-binutils
      hasRustAnalyzer = elem "rust-analyzer" extensions; # LSP server
      hasSrc = elem "rust-src" extensions; # std nav in rust-analyzer
      hasDocs = elem "rust-docs" extensions; # local rustup doc
    };

    targets = unique (
      optionals (isNotEmpty parsed) (parsed.targets or [])
      ++ optionals includeWeb ["wasm32-unknown-unknown"]
      ++ extraTargets
    );

    package = let
      rust =
        if pkgs ? rust-bin
        then pkgs.rust-bin
        else throw "lib.packages.mkRust: pkgs.rust-bin is required.";
    in
      if toolchain.file != null
      then rust.fromRustupToolchainFile toolchain.file
      else
        rust.${toolchain.channel}.latest.default.override {
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
in {inherit mkRust;}
