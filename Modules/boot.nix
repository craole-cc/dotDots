{
  host,
  lib,
  pkgs,
  ...
}: {
  boot = {
    kernelPackages = lib.mkIf ((host.packages.kernel or null) != null) pkgs.${host.packages.kernel};
    loader = {
      systemd-boot.enable = (host.interface.bootLoader or null) == "systemd-boot";
      efi.canTouchEfiVariables = true; # TODO: Make this dynamic
      timeout = host.interface.bootLoaderTimeout or 1;
    };
  };
}
