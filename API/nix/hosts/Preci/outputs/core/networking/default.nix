{
  lix,
  host,
  registry,
  infrastructure,
  ...
}: let
  inherit (infrastructure.core.functionalities) network;
  inherit (lix.lists) optional;
  inherit (lix.attrsets) recursiveUpdate;
  inherit (registry) inputs overlays;
in {
  networking = {
    hostName = host.name;
    hostId = host.id;
    networkmanager.enable = network;
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
    nixPath = [
      "nixos-config=${host.paths.roots.run}"
      "nixpkgs=${inputs.nixpkgs.path}"
    ];
  };

  nixpkgs = {
    pkgs = import inputs.nixpkgs {
      inherit (host) system;
      config =
        recursiveUpdate {allowUnfree = false;}
        host.config.nixpkgs;
      overlays =
        optional (host.functionalities.rust or false)
        (import overlays.rust-overlay);
    };
  };
}
