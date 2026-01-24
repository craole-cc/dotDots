# Templates/rust-workspace/flake.nix
{
  description = "Rust workspace environment";

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
          taplo # TOML
          deno # Markdown, JSON, TypeScript
          yamlfmt # YAML

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
        #> Create workspace Cargo.toml if it doesn't exist
        if [ ! -f Cargo.toml ]; then
          cat > Cargo.toml <<-'CARGO'
        	[workspace]
        	members = [
        	    "crates/*",
        	]
        	resolver = "2"

        	[workspace.package]
        	version = "0.1.0"
        	edition = "2024"
        	authors = ["Your Name <your.email@example.com>"]
        	license = "MIT OR Apache-2.0"
        	repository = "https://github.com/yourusername/yourproject"

        	[workspace.dependencies]
        	# Shared dependencies go here
        	# Example:
        	# serde = { version = "1.0", features = ["derive"] }
        	# tokio = { version = "1", features = ["full"] }

        	[profile.dev]
        	opt-level = 0

        	[profile.release]
        	opt-level = 3
        	lto = true
        	codegen-units = 1
        	CARGO
          printf "  ✓ Created workspace Cargo.toml\n"
        fi

        #> Create .cargo/config.toml if it doesn't exist
        if [ ! -f .cargo/config.toml ]; then
          mkdir -p .cargo
          cat > .cargo/config.toml <<-'CARGO_CONFIG'
        	[alias]
        	b = "build"
        	br = "build --release"
        	c = "check"
        	cl = "clippy --workspace"
        	t = "test --workspace"
        	r = "run"
        	rr = "run --release"
        	w = "watch -x check"
        	wr = "watch -x run"
        	wa = "watch -x 'check --workspace'"

        	[build]
        	jobs = 4

        	[term]
        	color = "always"
        	CARGO_CONFIG
          printf "  ✓ Created .cargo/config.toml with workspace aliases\n"
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
        	description = "Run all workspace tests"
        	run = "cargo nextest run --workspace"

        	[tasks.test-crate]
        	description = "Run tests for specific crate"
        	run = "cargo nextest run -p"

        	[tasks.coverage]
        	description = "Generate coverage report"
        	run = "cargo tarpaulin --workspace --out Html --output-dir coverage"

        	[tasks.bench]
        	description = "Run benchmarks"
        	run = "cargo bench --workspace"

        	[tasks.fmt]
        	description = "Format all files"
        	run = "treefmt"

        	[tasks.check]
        	description = "Format and clippy workspace"
        	run = "treefmt && cargo clippy --workspace"

        	[tasks.audit]
        	description = "Security audit"
        	run = "cargo audit"

        	[tasks.outdated]
        	description = "Check for outdated dependencies"
        	run = "cargo outdated --workspace"

        	[tasks.info]
        	description = "Show project info"
        	run = "onefetch"

        	[tasks.git]
        	description = "Open gitui"
        	run = "gitui"

        	[tasks.new-crate]
        	description = "Create new crate in workspace"
        	run = "mkdir -p crates && cd crates && cargo new"
        	MISE
          printf "  ✓ Created .mise.toml with workspace tasks\n"
        fi

        #> Create crates directory structure
        if [ ! -d crates ]; then
          mkdir -p crates
          printf "  ✓ Created crates/ directory for workspace members\n"
        fi

        #> Create example README if it doesn't exist
        if [ ! -f README.md ]; then
          cat > README.md <<-'README'
        	# Rust Workspace

        	A Rust workspace with multiple crates.

        	## Structure

        	```
        	.
        	├── Cargo.toml          # Workspace configuration
        	├── crates/             # Workspace members
        	│   ├── crate-one/
        	│   └── crate-two/
        	└── ...
        	```

        	## Quick Start

        	```bash
        	# Create a new crate
        	mise run new-crate my-crate

        	# Run tests for all crates
        	cargo test --workspace

        	# Run a specific crate
        	cargo run -p crate-name
        	```

        	## Development

        	- **Watch mode**: `mise run dev`
        	- **Test all**: `mise run test`
        	- **Format**: `mise run fmt`
        	- **Check**: `mise run check`

        	## License

        	MIT OR Apache-2.0
        	README
          printf "  ✓ Created README.md\n"
        fi
      '';

      #|───────────────────────────────────────────────────────────────────────|
      #| Shell Hook                                                            |
      #|───────────────────────────────────────────────────────────────────────|

      shellHook = ''
        cat <<-EOF
        	🦀 Rust Workspace Environment
        	==============================

        	Toolchain: Nightly ($(rustc --version | cut -d' ' -f2-))

        	Workspace Commands:
        	  mise run new-crate <n>   # Create new crate in workspace
        	  cargo b --workspace      # Build all crates
        	  cargo t --workspace      # Test all crates
        	  cargo r -p <crate>       # Run specific crate

        	Cargo Aliases (workspace-aware):
        	  cargo cl                 # Clippy on workspace
        	  cargo t                  # Test workspace
        	  cargo wa                 # Watch entire workspace

        	Mise Tasks:
        	  mise run dev             # Watch mode
        	  mise run test            # Test all crates
        	  mise run test-crate <n>  # Test specific crate
        	  mise run check           # Format + clippy workspace
        	  mise run outdated        # Check outdated deps
        	  mise run info            # Project info

        	EOF

        ${setupConfig}
      '';
    in {
      default = pkgs.mkShell {
        name = "rust-workspace";
        inherit packages shellHook;
        RUST_BACKTRACE = "full";
        RUST_LOG = "info";
        CARGO_INCREMENTAL = "1";
      };
    });
  };
}
