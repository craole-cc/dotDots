{ ... }:

{
  imports = [
    #/> Configuration                               <\
    ../../configuration

    #/> Services                                    <\
    ../../services/filesystem
    ../../services/autorandr.nix
    ../../services/bluetooth.nix
    ../../services/gvfs.nix
    ../../services/printing.nix
    ../../services/pipewire.nix
    ../../services/redshift.nix
    ../../services/upower.nix

    #/> Packages                                    <\
    ../../packages/core
  ];
}
