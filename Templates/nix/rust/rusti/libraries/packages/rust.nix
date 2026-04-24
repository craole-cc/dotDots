{lib}: let
  inherit (lib.trivial) pathExists;
  /**
  Select a rust-overlay toolchain derivation.

  Defaults intentionally include the components expected by the Rust shell and
  editor tooling.

  # Type
  ```nix
  mkRust :: {
    pkgs :: AttrSet;
    channel ? string;
    targets ? [string];
    extensions ? [string];
  } -> derivation
  ```

  # Examples
  ```nix
  mkRust {
    inherit pkgs;
    channel = "stable";
  }
  # => pkgs.rust-bin.stable.latest.default.override { ... }
  ```

  # Returns
  A rust-overlay toolchain derivation with the requested channel, targets, and extensions.
  */
  mkRust = {
    pkgs,
    channel ? null,
    targets ? null,
    extensions ? null,
    toolchainFile ? null,
  }: let
    package = pkgs.rust-bin;

    toolchain = {
      root = ../../rust-toolchain.toml;
      template = ../../templates/rust-toolchain.toml;
    };
  in
    if toolchainFile != null && pathExists toolchainFile
    then package.fromRustupToolchainFile toolchainFile
    else if pathExists toolchain.root
    then package.fromRustupToolchainFile toolchain.root
    else if pathExists toolchain.template
    then package.fromRustupToolchainFile toolchain.template
    else
      package.${
        if channel != null
        then channel
        else "nightly"
      }.latest.default.override {
        targets =
          if targets != null
          then targets
          else ["wasm32-unknown-unknown"];
        extensions =
          if extensions != null
          then extensions
          else [
            "cargo"
            "clippy"
            "rust-analyzer"
            "rust-docs"
            "rust-src"
            "rust-std"
            "rustc"
            "rustfmt"
          ];
      };
in {inherit mkRust;}
