{lib, ...}: let
  inherit (lib.lists) elem;
  inherit (lib.strings) hasPrefix;

  isSystemDefaultUser = name:
    (hasPrefix "nixbld" name)
    || (hasPrefix "systemd-" name)
    || (hasPrefix "systemd-" name)
    || (elem name [
      "dhcpcd"
      "fwupd-refresh"
      "geoclue"
      "messagebus"
      "nm-iodine"
      "nm-openvpn"
      "nobody"
      "nscd"
      "polkituser"
      "root"
      "rtkit"
      "sddm"
      "gdm"
    ]);
  exports = {inherit isSystemDefaultUser;};
in
  exports // {_rootAliases = exports;}
