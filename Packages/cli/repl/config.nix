{
  lib,
  host,
  helpers,
}: let
  hostInfo = helpers.hostInfo host.name;
  users = hostInfo.users;
  inherit (hostInfo) programs services variables aliases packages;
in {
  inherit users programs services variables aliases packages;
}
