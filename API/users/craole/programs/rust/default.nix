{
  lib,
  pkgs,
  policies,
  ...
}: {
  config = lib.mkIf (policies.dev) {
    home.packages = with pkgs; [
      rustup
      # gcc
      # clang
      # rust-script
    ];
    programs = {
      bacon = import ./bacon.nix;
      cargo = import ./cargo.nix;
    };
  };
}
