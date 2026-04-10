{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: let
  # Joins core rust tools and standard library source into one path
  rust-toolchain = pkgs.symlinkJoin {
    name = "rust-toolchain";
    paths = [
      pkgs.rustc
      pkgs.cargo
      pkgs.rustPlatform.rustcSrc
    ];
  };
in
  pkgs.mkShell {
    name = "rust-dev-shell";

    buildInputs = [
      rust-toolchain
      pkgs.jetbrains.rust-rover
      # Common dependencies for Rust projects
      pkgs.pkg-config
      pkgs.openssl
    ];

    # Tells tools where to find the standard library source code
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustcSrc}";

    shellHook = ''
      echo "RustRover development shell active."
      echo "Run 'rust-rover' to start the IDE."
    '';
  }
