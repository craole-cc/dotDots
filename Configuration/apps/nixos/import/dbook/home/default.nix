{config, ...}: let
  inherit (config.DOTS) alpha;
in {
  imports = [
    <home-manager/nixos>
    # ./apps
    # ./stylix.nix
  ];

  home-manager = let
  in {
    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
    backupFileExtension = "BaC";
    users.${alpha} = {osConfig, ...}: {
      imports = [(./configurations + "/${alpha}")];
      home = {
        inherit (osConfig.system) stateVersion;
      };
    };
  };
}
