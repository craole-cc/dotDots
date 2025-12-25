{
  pkgs,
  inputs,
  system,
}: let
  pkgs' = import inputs.nixpkgs {
    inherit system;
    overlays = [(import inputs.rust-overlay)];
  };
  rustNightly = pkgs'.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);
  # packages = with rustNightly; [
  #   rustc
  #   cargo
  #   rust-analyzer
  #   clippy
  #   rustfmt
  #   rust-script
  #   cargo-watch
  #   cargo-edit
  # ];
  packages = [rustNightly];

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
