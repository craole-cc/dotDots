{
  pkgs,
  inputs,
  system,
  platform,
}: let
  inherit (pkgs.lib.lists) optionals;

  pkgs' = import inputs.nixpkgs {
    inherit system;
    overlays = [(import inputs.rust-overlay)];
  };

  rustNightly = pkgs'.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);

  packages =
    [rustNightly]
    ++ (
      with pkgs;
      with platform;
        optionals isLinux [] ++ optionals isDarwin [libiconv]
    );

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
