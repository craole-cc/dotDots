{ config, ... }:
let
  inherit (config.DOTS.users.alpha) name;
in
{
  imports = [
    <home-manager/nixos>
    # ./apps
    # ./stylix.nix
  ];

  home-manager =
    let
    in
    {
      useUserPackages = true;
      useGlobalPkgs = true;
      verbose = true;
      backupFileExtension = "BaC";
      users.${name} =
        { osConfig, ... }:
        {
          imports = [ (./configurations + "/${name}") ];
          home = {
            inherit (osConfig.system) stateVersion;
          };
        };
    };
}
