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
    channel ? "nightly",
    targets ? [],
    extensions ? [
      "clippy"
      "rust-analyzer"
      "rust-src"
      "rustfmt"
    ],
  }:
    pkgs.rust-bin.${channel}.latest.default.override {
      inherit targets extensions;
    };
}
