{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs
    nodePackages_latest.pnpm
    yarn
  ];
}
