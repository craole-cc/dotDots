{ ... }:
{
  imports = [
    ./options.nix

    ./service.nix
    ./security.nix
    ./tls.nix
    ./networking.nix
    ./secrets.nix
  ];
}
