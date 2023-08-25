{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    noto-fonts-emoji
    # nerdfonts
    font-manager
    fontfor
    # fontmatrix #issue with "qtwebkit-5.212.0-alpha4"
  ];
}
