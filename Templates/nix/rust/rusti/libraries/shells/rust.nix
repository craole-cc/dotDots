{lib}: let
  inherit (lib.lists) optionals;
  inherit (lib.packages) mkPkgs mkRust;
  inherit (lib.strings) concatStringsSep optionalString;
  inherit (lib.trivial) isEmpty isNotEmpty;
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
    pkgs ? null,
    channel ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
    minimal ? false,
  }: let
    pkgs' =
      if isNotEmpty pkgs
      then pkgs
      else mkPkgs {};

    rust = mkRust {
      inherit
        channel
        targets
        extensions
        ;
      pkgs = pkgs';
    };

    ch = rust.toolchain.channel;
    inherit (rust) kind;

    name =
      if isEmpty channel
      then concatStringsSep "-" [kind ch]
      else "rust-${channel}";

    env = let
    in {
      RUST_SRC_PATH = "${rust.package}/lib/rustlib/src/rust/library";
      RUSTFLAGS = optionalString (ch == "nightly") "-Z macro-backtrace";
      RUST_BACKTRACE =
        if ch == "stable"
        then "0"
        else "1";
    };

    packages = {
      core = with pkgs'; [rust.package gcc];
      full = optionals (!minimal) (with pkgs'; [
        #~@ Development
        cargo-leptos
        trunk
        binaryen
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
        leptosfmt
        markdownlint-cli2
        prettierd
        rustfmt
        taplo
        treefmt
        yamlfmt
        cargo-make
      ]);
      nightly = optionals (ch == "nightly" && !minimal) (with pkgs'; [cargo-careful]);
      editor = optionals (includeEditor && !minimal) (with pkgs'; [helix jetbrains.rust-rover]);
      darwin = optionals pkgs'.stdenv.isDarwin (with pkgs'; [libiconv]);
    };

    shellHook = ''
      printf "🦀 Rust"
      ${
        optionalString (rust.toolchain.source == "file")
        ''printf "  Toolchain: %s\n" "${toString rust.toolchain.file}"''
      }
      printf "    Channel: %s\n" "${rust.toolchain.channel}"
      printf "    Version: %s\n" "${rust.version}"
    '';
    shell = {
      inherit name env shellHook;
      packages =
        []
        ++ packages.core
        ++ packages.full
        ++ packages.nightly
        ++ packages.editor
        ++ packages.darwin;
    };
  in {
    __meta = rust // shell;
    inherit shell;
  };

  mkRustSuite = {pkgs ? null}: let
    mk = args: mkRustSpec ({inherit pkgs;} // args);
  in {
    #~@ Full suite — with editor
    rust-nightly = mk {channel = "nightly";};
    rust-stable = mk {channel = "stable";};
    rust-beta = mk {channel = "beta";};

    #~@Lean — full tooling, no editor
    rust-nightly-lean = mk {
      channel = "nightly";
      includeEditor = false;
    };
    rust-stable-lean = mk {
      channel = "stable";
      includeEditor = false;
    };

    #~@ Minimal — toolchain + gcc only, no dev tools, no editor
    rust-nightly-minimal = mk {
      channel = "nightly";
      minimal = true;
    };
    rust-stable-minimal = mk {
      channel = "stable";
      minimal = true;
    };
  };
in {
  inherit mkRustSpec mkRustSuite;
  mkRust = mkRustSpec;
  mkRustShells = mkRustSuite;
}
