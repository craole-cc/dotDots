{ config, lib, pkgs, ... }: {
  imports = [
    ./emacs
    ./firefox
    ./tex
    ./tablet
    ./virt
    ./keyboard
    ./hidden
    ./home-manager
    ./tmux
  ];
}
