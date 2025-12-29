{
  host,
  lib,
  lix,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (lix.modules.core) mkFileSystem mkSwapDevice;
in {
  fileSystems = mapAttrs mkFileSystem (host.devices.file or {});
  swapDevices = map mkSwapDevice (host.devices.swap or []);
}
