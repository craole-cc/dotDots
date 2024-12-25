{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) dot;
  inherit (dot.current) host;
in
with host;
{
  config = lib.mkIf (machine == "server") {
    hardware = { };
    services = { };
    environment.systemPackages = with pkgs; [ ];
  };
}
