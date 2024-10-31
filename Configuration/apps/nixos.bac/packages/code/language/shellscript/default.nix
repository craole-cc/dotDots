{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    shfmt
    shellcheck
    shellharden
    rust-script
  ];
}
