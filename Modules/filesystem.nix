{
  host,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  mkFileSystem = _: fs: let
    base = {
      device = fs.device;
      fsType = fs.fsType;
    };
    opts = fs.options or [];
  in
    #> Combine base attributes with options if they exist.
    if opts == []
    then base
    else base // {options = opts;};
  mkSwapDevice = s: {device = s.device;};
in {
  fileSystems = mapAttrs mkFileSystem (host.devices.file or {});
  swapDevices = map mkSwapDevice (host.devices.swap or []);
}
