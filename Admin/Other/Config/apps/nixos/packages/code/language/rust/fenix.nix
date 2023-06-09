{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly
    vscode-extensions.rust-lang.rust-analyzer-nightly
  ];
}
