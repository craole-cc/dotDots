{
  _,
  lib,
  ...
}: let
  inherit (lib.list) elem;
  inherit (lib.strings) hasPrefix;

  isSystemDefaultUser = name:
    (hasPrefix "nixbld" name)
    || (elem name [
      "root"
      "nobody"
      "messagebus"
      "systemd-coredump"
      "systemd-network"
      "systemd-oom"
      "systemd-resolve"
      "systemd-timesync"
      "polkituser"
      "rtkit"
      "geoclue"
      "nscd"
      "sddm"
      "dhcpcd"
      "fwupd-refresh"
      "nm-iodine"
      "nm-openvpn"
    ]);
  exports = {inherit isSystemDefaultUser;};
in
  exports // {_rootAliases = exports;}
