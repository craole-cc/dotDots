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
        config.allowUnfree = true;
      };
      inherit (pkgs.lib.lists) optionals;
      inherit (pkgs.stdenv) isDarwin;

      #|───────────────────────────────────────────────────────────────────────|
      #| Rust Toolchain                                                        |
      #|───────────────────────────────────────────────────────────────────────|

      toolchains = with pkgs.rust-bin; {
        nightly = selectLatestNightlyWith (toolchain:
          toolchain.default.override {
            extensions = ["rust-src" "rust-analyzer" "rustfmt" "clippy"];
          });
        beta = beta.latest.default;
        stable = stable.latest.default;
      };

      #|───────────────────────────────────────────────────────────────────────|
      #| Packages                                                              |
      #|───────────────────────────────────────────────────────────────────────|

      packages =
        [toolchains.nightly]
        ++ (with pkgs; [
          #~@ Editor
          jetbrains.rust-rover

          #~@ Build Essentials
          gcc

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
          treefmt
          rustfmt
          taplo #? TOML
          deno #? Markdown, JSON, TypeScript
          yamlfmt #? YAML

          #~@ Git & Project Info
          gitui
          onefetch

          #~@ Utilities
          rust-script
          mise
        ])
        ++ optionals isDarwin [pkgs.libiconv];

      #|───────────────────────────────────────────────────────────────────────|
      #| Setup Configuration Files                                             |
      #|───────────────────────────────────────────────────────────────────────|

      setupConfig = ''
        #> Create .cargo/config.toml if it doesn't exist
        if [ ! -f .cargo/config.toml ]; then
          mkdir -p .cargo
          cat > .cargo/config.toml <<-'CARGO'
        	[alias]
        	b = "build"
        	br = "build --release"
        	c = "check"
        	cl = "clippy"
        	t = "test"
        	r = "run"
        	rr = "run --release"
        	w = "watch -x check"
        	wr = "watch -x run"

        	[build]
        	jobs = 4

        	[term]
        	color = "always"
        	CARGO
          printf "  ✓ Created .cargo/config.toml with common aliases\n"
        fi

        #> Create treefmt.toml if it doesn't exist
        if [ ! -f treefmt.toml ]; then
          cat > treefmt.toml <<-'TREEFMT'
        	[formatter.rust]
        	command = "rustfmt"
        	options = ["--edition", "2024"]
        	includes = ["*.rs"]

        	[formatter.toml]
        	command = "taplo"
        	options = ["format"]
        	includes = ["*.toml"]

        	[formatter.markdown]
        	command = "deno"
        	options = ["fmt"]
        	includes = ["*.md", "*.json"]

        	[formatter.yaml]
        	command = "yamlfmt"
        	includes = ["*.yaml", "*.yml"]
        	TREEFMT
          printf "  ✓ Created treefmt.toml for multi-language formatting\n"
        fi

        #> Create .mise.toml if it doesn't exist
        if [ ! -f .mise.toml ]; then
          cat > .mise.toml <<-'MISE'
        	[tasks.dev]
        	description = "Run in watch mode"
        	run = "bacon"

        	[tasks.test]
        	description = "Run tests"
        	run = "cargo nextest run"

        	[tasks.coverage]
        	description = "Generate coverage report"
        	run = "cargo tarpaulin --out Html --output-dir coverage"

        	[tasks.bench]
        	description = "Run benchmarks"
        	run = "cargo bench"

        	[tasks.fmt]
        	description = "Format all files"
        	run = "treefmt"

        	[tasks.check]
        	description = "Format and clippy"
        	run = "treefmt && cargo clippy"

        	[tasks.audit]
        	description = "Security audit"
        	run = "cargo audit"

        	[tasks.info]
        	description = "Show project info"
        	run = "onefetch"

        	[tasks.git]
        	description = "Open gitui"
        	run = "gitui"
        	MISE
          printf "  ✓ Created .mise.toml with common tasks\n"
        fi
      '';

      #|───────────────────────────────────────────────────────────────────────|
      #| Shell Hook                                                            |
      #|───────────────────────────────────────────────────────────────────────|

      shellHook = ''
        cat <<-EOF
        	🦀 Rust Development Environment
        	================================

        	Toolchain: Nightly ($(rustc --version | cut -d' ' -f2-))

        	Quick Start:
        	  cargo init <name>    # Create new project
        	  cargo new <name>     # Create with git

        	Cargo Aliases (via .cargo/config.toml):
        	  cargo b/br           # build / build release
        	  cargo c/cl           # check / clippy
        	  cargo t/r/rr         # test / run / run release
        	  cargo w/wr           # watch check / watch run

        	Mise Tasks (via .mise.toml):
        	  mise run dev         # Watch mode with bacon
        	  mise run test        # Run tests with nextest
        	  mise run coverage    # Generate coverage report
        	  mise run fmt         # Format & clippy
        	  mise run audit       # Security audit

        	EOF

        ${setupConfig}
      '';
    in {
      default = pkgs.mkShell {
        name = "rust-dev";
        inherit packages shellHook;
        RUST_SRC_PATH = "${toolchains.nightly}/lib/rustlib/src/rust/library";
        # _JAVA_AWT_WM_NONREPARENTING = "1";
        RUST_BACKTRACE = "full";
        RUST_LOG = "info";
        CARGO_INCREMENTAL = "1";
      };
    });
  };
}
