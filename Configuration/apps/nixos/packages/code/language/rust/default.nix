{ pkgs, ... }:

{
  imports = [
    ./rust.nix
    # ./rustup.nix
    # ./fenix.nix
    # ./oxalica.nix
  ];

  environment.systemPackages = with pkgs; [
    openssl
    pkg-config
    llvmPackages.bintools-unwrapped
    # cargo-binutils
    # cargo-watch
    # cargo-lock
    # cargo-bloat
    # cargo-limit
    # cargo-tauri
    # cargo-update
    # cargo-readme
    # cargo-feature
    # cargo-workspaces
    # cargo-spellcheck
    # cargo-whatfeatures
    # cargo-unused-features
  ];
}
