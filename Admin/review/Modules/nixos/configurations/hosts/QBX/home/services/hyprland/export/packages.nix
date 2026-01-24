{pkgs, ...}: {
  home.packages = with pkgs; [
    # rofi-wayland
    bemenu
    # tofi

    grim
    slurp
    wl-clipboard
    qalculate-qt
    wlprop
    entr
  ];
}
