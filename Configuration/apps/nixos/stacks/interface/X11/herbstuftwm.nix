{ ... }:

{
  imports = [
    #/> Core                                                       <\
    ../../services/desktopManager
    ../../services/desktopManager/xfce-minimal.nix
    ../../services/windowManager/herbstuftwm.nix

    #/> Packages                                                   <\
    ../../packages/app
    ../../packages/style
    ../../packages/utility
    ../../packages/web
  ];
}
