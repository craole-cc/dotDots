{ ... }:

{
  imports = [
    #| Desktop Environment
    #./desktopManager/gnome.nix
    # ./desktopManager/kde.nix
    # ./desktopManager/pantheon.nix

    #| Window Manager
    ./windowManager/qtile.nix
    # ./windowManager/xmonad.nix
    # ./windowManager/herbstluftwm.nix

    #| Display Manager
    ./displayManager/sddm.nix
    # ./displayManager/lightdm
    # ./displayManager/gdm
  ];
}
