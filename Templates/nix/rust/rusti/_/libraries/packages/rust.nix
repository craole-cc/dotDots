{lib}: let
  inherit (lib.trivial) fromTOML readFile pathExists;
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
    toolchain ? null,
  }: let
    resolved = {
      toolchain = {
        file = let
          root = ../../rust-toolchain.toml;
          template = ../../templates/rust-toolchain.toml;
        in
          if toolchain != null && pathExists toolchain
          then toolchain
          else if pathExists root
          then root
          else if pathExists template
          then template
          else null;

        channel = let
          fromFile =
            if resolved.toolchain.file != null
            then (fromTOML (readFile resolved.toolchain.file)).toolchain.channel or null
            else null;
        in
          if fromFile != null
          then fromFile
          else if channel != null
          then channel
          else "nightly";

        source =
          if resolved.toolchain.file != null
          then "file"
          else "string";
      };

      package = let
        rust =
          if pkgs?rust-bin
          then pkgs.rust-bin
          else throw "lib.shells.mkRust: pkgs.rust-bin is required.";
      in
        if resolved.toolchain.file != null
        then rust.fromRustupToolchainFile resolved.toolchain.file
        else
          rust.${resolved.toolchain.channel}.latest.default.override {
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
    };
  in {
    kind = "rust";
    inherit (resolved) toolchain package;
    inherit (resolved.package) paths version system;
    inherit (resolved.toolchain) channel;
  };
in {inherit mkRust;}
