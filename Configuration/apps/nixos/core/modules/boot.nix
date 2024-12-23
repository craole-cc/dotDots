{ specialArgs, lib, ... }:
let
  inherit (lib.lists) elem;
  inherit (lib.attrsets) listToAttrs mapAttrs;
  inherit (specialArgs.host)
    boot
    devices
    ;
  inherit (boot) modules;
  inherit (cpu) brand;
in
{
  boot = {
    initrd = {
      availableKernelModules = modules;
      luks.devices = devices.luks;
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelModules =
      if
        (elem brand [
          "intel"
          "amd"
          # "x86"
        ])
      then
        [ "kvm-${brand}" ]
      else
        [ ];
    extraModulePackages = [ ];
  };

  inherit (devices) fileSystems swapDevices;
}
