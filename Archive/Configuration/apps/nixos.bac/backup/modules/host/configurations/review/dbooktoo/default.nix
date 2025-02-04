{ config, lib, ... }:
let
  inherit (config.networking) hostName;
  host = "dbooktoo";
in
{

  imports = [ ./hardware-configuration.nix ];

  config.dots.hosts.${host} = lib.mkIf (hostName == host) {
    id = "6d409aea";
    type = "chromebook";
    context = [ "entertainment" ];
  };
}
