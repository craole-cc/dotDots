{host, pkgs, ...}: {
  boot = {
    loader = {
      grub = {
        enable = host.interface.boot.loader.manager == "grub";
        device = host.interface.boot.loader.device;
        useOSProber = true;
        fsIdentifier = "provided";
      };

      systemd-boot = {
        enable = host.interface.boot.loader.manager == "systemd-boot";
        consoleMode = "max";
      };

      timeout = host.interface.boot.loader.timeout;
    };

    kernelPackages = pkgs.${host.packages.kernel};
  };
}
