{ config, ... }:
let
  inherit (config) dot;
  inherit (dot.active) host user;
in
{

  options.dot.programs.home-manager = {
    extraSpecialArgs = {
      inherit dot host user;
    };
    useUserPackages = true;
    useGlobalPkgs = true;
    verbose = true;
    backupFileExtension = "BaC";
  };
}
