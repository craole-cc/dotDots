{
  lib,
  host,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (host.devices) file swap;

  # Helper to construct a single swap device entry for swapDevices list.
  mkSwapDevice = s: {device = s.device;};

  # Helper to construct a single file system entry for fileSystems map.
  mkFileSystem = _: fs: let
    base = {
      device = fs.device;
      fsType = fs.fsType;
    };
    opts = fs.options or [];
  in
    # Combine base attributes with options if they exist.
    if opts == []
    then base
    else base // {options = opts;};
in {
  fileSystems = mapAttrs mkFileSystem file;
  swapDevices = map mkSwapDevice swap;
}
