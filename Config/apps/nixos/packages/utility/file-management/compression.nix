{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lz4
    p7zip
    unzip
    unrar
    zip
    xar
  ];
}
