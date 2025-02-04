{ ... }:

{
  imports = [
    #/> Core                                        <\
    ../default.nix

    #/> Services                                    <\
    ../../../services/xserver
    ../../../services/picom.nix

    #/> Packages                                    <\
    ../../../packages/base/X11.nix

  ];
}
