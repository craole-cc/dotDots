{ ... }:

{
  imports = [
    # /etc/nixos/hardware-configuration.nix
    ./hardware.nix
    ./host.nix
  ];
}
