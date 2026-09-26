{
  host,
  inputs,
  infrastructure,
  ...
}: let
  inherit (infrastructure.core.functionalities) network;
in {
  networking = {
    hostName = host.name;
    hostId = host.id;
    networkmanager.enable = network;
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    nixPath = [
      "nixos-config=${host.paths.roots.run}"
      "nixpkgs=${inputs.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    pkgs = inputs.modules.nixpkgs;
  };
}
