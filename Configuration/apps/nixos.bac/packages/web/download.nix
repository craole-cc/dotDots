{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qbittorrent
    gitFull
    gh
    curl
    wget
  ];
}
