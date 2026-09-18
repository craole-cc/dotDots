{pkgs, ...}: let
  nightly = pkgs.rust-bin.selectLatestNightlyWith (toolchain:
    toolchain.default.override {
      extensions = [
        "rust-src"
        "rust-analyzer"
        "rustfmt"
        "clippy"
      ];
    });
in {
  # Keep the Nix toolchain before rustup's compatibility shims while exposing
  # binaries installed by `cargo install` to every craole session.
  home.sessionPath = [
    "${nightly}/bin"
    "$HOME/.cargo/bin"
  ];
}
