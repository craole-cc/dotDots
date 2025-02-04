{ specialArgs, lib, ... }:
let
  inherit (lib.lists) elem;
  inherit (specialArgs.host)
    boot
    devices
    cpu
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
      timeout = boot.timeout or 1;
    };

    kernelModules =
      if
        (elem brand [
          "intel"
          "amd"
          "x86"
        ])
      then
        [ "kvm-${brand}" ]
      else
        [ ];
    extraModulePackages = [ ];
  };

  inherit (devices) fileSystems swapDevices;
}
