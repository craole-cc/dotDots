{ ... }:

{
  imports = [
    ./filesystem
    # ./authentication.nix
    ./autorandr.nix
    ./bluetooth.nix
    ./pipewire.nix
    ./printing.nix
    # ./picom.nix
    ./redshift.nix
    ./upower.nix
  ];
}
