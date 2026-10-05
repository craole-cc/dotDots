{
  context,
  host,
  ...
}: let
  inherit (context.packages) kernel;
  inherit (host.interface.boot.loader) device manager timeout;
in {
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
