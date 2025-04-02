{ dots, ... }:
{
  imports = [
    ./nix.nix
    # ./env.nix
    ./pkg.nix
    # ./wsl.nix
  ];

  networking.hostName = "QBXL";
  system.stateVersion = "24.11";
  environment = { inherit (dots) variables; };
}
