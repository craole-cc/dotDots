{host, infrastructure, ...}: let 
inherit (host.interface.boot.loader}device manager timeout; inherit (infrastructure.core.packages)kernel;
in{
  boot = {
    loader = {
      grub = {
        enable = manager == "grub";
       inherit device;
        useOSProber = true;
        fsIdentifier = "provided";
      };

      systemd-boot = {
        enable = manager == "systemd-boot";
        consoleMode = "max";
      };

      inherit timeout;
    };

    kernelPackages = kernel.package;
  };
}
