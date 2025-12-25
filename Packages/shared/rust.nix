{pkgs}: let
  packages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    rust-script
    cargo-watch
    cargo-edit
  ];

  env = {
    RUST_BACKTRACE = "1";
    RUST_LOG = "debug";
  };

  shellHook = ''
    echo "🦀 Rust Development Shell"
    echo "========================="
    echo ""
    echo "Rust: $(rustc --version)"
    echo "Cargo: $(cargo --version)"
    echo ""
  '';
in
  pkgs.mkShell {
    name = "rust-dev";
    inherit packages env shellHook;
  }
