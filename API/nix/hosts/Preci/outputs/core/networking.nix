{host, inputs, lix, ...}: {
  networking = {
    hostName = host.name;
    hostId = host.id;
    networkmanager.enable = lix.lists.elem "network" host.functionalities;
  };

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    nixPath = [
      "nixos-config=" + host.paths.roots.run + "/default.nix"
      "nixpkgs=" + inputs.nixpkgs.path
    ];
  };

  nixpkgs = {
    config.allowUnfree = true;
    pkgs = inputs.nixpkgs;
  };
}
