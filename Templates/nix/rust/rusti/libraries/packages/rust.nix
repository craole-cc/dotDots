/**
libraries/packages/rust.nix

Rust toolchain selectors for lib.packages.
*/
{lib}: {
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
  }: let
    channel' =
      if channel != null
      then channel
      else "nightly";

    extensions' =
      if extensions != null
      then extensions
      else [
        "clippy"
        "rust-analyzer"
        "rust-src"
        "rustfmt"
      ];

    targets' =
      if targets != null
      then targets
      else [
        #? Windows x86_64 (Intel/AMD) - Most common Windows desktops/laptops
        # "x86_64-pc-windows-msvc"

        #? Windows ARM64 - Newer ARM-based Windows devices (Surface Pro X, etc)
        # "aarch64-pc-windows-msvc"

        #? macOS x86_64 (Intel) - Intel-based Mac desktops/laptops
        # "x86_64-apple-darwin"

        #? macOS ARM64 (Apple Silicon) - M1/M2/M3 Macs (Apple Silicon)
        # "aarch64-apple-darwin"

        #? Linux x86_64 - Most common Linux desktops/laptops (GNOME, KDE, Cinnamon, etc)[3]
        # "x86_64-unknown-linux-gnu"
        # "x86_64-unknown-linux-musl"

        #? Linux ARMv7 (Pi 2/3/4, 32-bit OS) - Raspberry Pi 2/3/4 running 32-bit desktop Linux
        # "armv7-unknown-linux-gnueabihf"

        #? Linux ARM64 (Pi 3/4, 64-bit OS) - Raspberry Pi 3/4 running 64-bit desktop Linux
        # "aarch64-unknown-linux-gnu"
        # "aarch64-unknown-linux-musl"

        #? WebAssembly
        "wasm32-unknown-unknown"
      ];
    package = pkgs.rust-bin.${channel'}.latest.default.override {
      targets = targets';
      extensions = extensions';
    };
  in
    package;
}
