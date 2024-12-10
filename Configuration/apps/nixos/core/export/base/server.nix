{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (specialArgs) host;
  inherit (lib.lists) elem;
  inherit (lib.modules) mkIf;
in
{
  config = lib.mkIf (elem host.base [ "server" ]) {
    hardware = { };
    services = { };
    environment.systemPackages = with pkgs; [ ];
  };
}
