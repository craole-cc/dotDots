{host, infrastructure, ...}: let 
inherit (host.interface.boot.loader}device manager timeout;
in{
  boot = {
    loader = {
      grub = {
        enable = host.interface.boot.loader.manager == "grub";
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

    kernelPackages = infrastructure.core.packages.kernel.package;
  };
}
