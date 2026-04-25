{lib}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.lists) optionals;
  inherit (lib.packages) mkRust;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.trivial) isEmpty;
  /**
  Build the Rust-focused shell specification.

  # Type
  ```nix
  mkRustSpec :: AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  mkRustSpec {
    inherit lib pkgs mkTools mkEnvironment mkTemplates mkWelcome;
    channel = "stable";
  }
  # => {
  #   __meta.kind = "rust";
  #   shell.name = "rust-stable";
  #   ...
  # }
  ```

  # Returns
  A shell spec containing Rust packages, environment variables, and shell initialization.
  */
  mkRustSpec = {
    pkgs,
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
  }: let
    rust = mkRust {
      inherit
        pkgs
        channel
        targets
        extensions
        ;
    };

    name =
      if isEmpty channel
      then concatStringsSep "-" [rust.kind rust.toolchain.channel]
      else "rust-${channel}";

    env = let
      ch = rust.toolchain.channel;
    in {
      # rust-analyzer needs this; rust-src is included in the derivation
      RUST_SRC_PATH = "${rust.package}/lib/rustlib/src/rust/library";

      # Nightly allows -Z flags; expose that clearly
      RUSTFLAGS =
        if ch == "nightly"
        then "-Z macro-backtrace"
        else "";

      # More verbose backtraces on nightly (dev ergonomics)
      RUST_BACKTRACE =
        if ch == "stable"
        then "0"
        else "1";
    };

    packages = let
      base = with pkgs; [
        #~@ Build Essentials
        gcc
        #~@ Development
        cargo-leptos
        trunk
        binaryen
        #~@ Build & Watch
        cargo-watch
        cargo-make
        bacon
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
        leptosfmt
        markdownlint-cli2
        prettierd
        # deno
        rustfmt
        taplo
        treefmt
        yamlfmt
      ];

      nightly = with pkgs;
        optionals (ch == "nightly") [
          cargo-careful #? runs tests under strict undefined-behaviour checks
        ];

      editor = optionals includeEditor (with pkgs; [
        helix
        jetbrains.rust-rover
      ]);

      darwin = optionals pkgs.stdenv.isDarwin (with pkgs; [
        libiconv
      ]);
    in
      base ++ nightly ++ editor ++ darwin;

    shellHook = ''

    '';
  in {
    __meta =
      rust
      // {
        inherit
          name
          # channel
          env
          # packages
          shellHook
          # tools
          ;
      };

    # shell = {inherit name packages env shellHook;};
  };
in {inherit mkRustSpec;}
