{
  nixosConfig,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  loc = nixosConfig.location or {};
  lat = loc.latitude or null;
  lng = loc.longitude or null;
  usegeoclue = (loc.provider or null) == "geoclue2";
  enable = (lat != null) && (lng != null);
in {
  services.darkman = mkIf enable {
    inherit enable;
    settings = {inherit lat lng usegeoclue;};
  };
}
