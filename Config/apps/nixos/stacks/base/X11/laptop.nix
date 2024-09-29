{ ... }:

{
  imports = [
    #/> Core                                        <\
    ../default.nix

    #/> Services                                    <\
    ../../../services/xserver/touchpad.nix

    #/> Packages                                    <\

  ];
}
