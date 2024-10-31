{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # rust-bin.fromRustupToolchainFile ./rust-toolchain
    rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
    # rust-bin.selectLatestNightlyWith (toolchain: toolchain.default) # or `toolchain.minimal`
    # rust-bin.nightly."2023-03-28".default
    # rust-bin.selectLatestNightlyWith
    # (toolchain: toolchain.default.override {
    #   extensions = [  "rustfmt" "rustc-dev" "rust-src" ];
    #   targets = [ "wasm32-unknown-unknown" ];
    # })

  ];
}
