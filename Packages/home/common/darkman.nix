{
  nixosConfig,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (nixosConfig) location;
  lat = location.latitude or null;
  lng = location.longitude or null;
  usegeoclue = (location.provider or null) == "geoclue2";
  enable = (lat != null) && (lng != null);
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
  };
}
