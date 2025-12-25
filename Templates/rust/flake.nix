{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in {
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };
      inherit (pkgs.lib.lists) optionals;
      inherit (pkgs.stdenv) isDarwin;

      toolchains = with pkgs.rust-bin; {
        nightly = selectLatestNightlyWith (toolchain:
          toolchain.default.override {
            extensions = ["rust-src" "rust-analyzer" "rustfmt" "clippy"];
          });
        beta = beta.latest.default;
        stable = stable.latest.default;
      };

      packages =
        [toolchains.nightly]
        ++ (with pkgs; [
          cargo-watch
          cargo-make
          bacon
          cargo-edit
          cargo-outdated
          cargo-audit
          cargo-deny
          cargo-flamegraph
          cargo-bloat
          cargo-expand
          cargo-nextest
          cargo-tarpaulin
          cargo-doc
          rust-script
        ])
        ++ optionals isDarwin [pkgs.libiconv];

      shellHook = ''
        cat <<-EOF
        	🦀 Rust Development Environment
        	================================

        	Toolchain: Nightly ($(rustc --version | cut -d' ' -f2-))

        	Quick Start:
        	  cargo init <name>    # Create new project
        	  cargo new <name>     # Create with git
        	  bacon                # Continuous checking

        	EOF
      '';
    in {
      default = pkgs.mkShell {
        name = "rust-dev";
        inherit packages shellHook;
        RUST_BACKTRACE = "full";
        RUST_LOG = "info";
        CARGO_INCREMENTAL = "1";
      };
    });
  };
}
