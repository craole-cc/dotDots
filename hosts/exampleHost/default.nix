# #
##
##  per-host configuration for exampleHost
##
##
{
  system,
  pkgs,
  ...
}: {
  inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = ["nvme-HFM256GDJTNG-8310A_CY9CN00281150CJ46"];
      immutable = false;
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
      removableEfi = true;
      kernelParams = [];
      sshUnlock = {
        # read sshUnlock.txt file.
        enable = false;
        authorizedKeys = [];
      };
    };
    networking = {
      # read changeHostName.txt file.
      hostName = "a3k";
      #hostName = "exampleHost";
      timeZone = "America/Jamaica";
      hostId = "2c4a22f0";
    };
  };

  # To add more options to per-host configuration, you can create a
  # custom configuration module, then add it here.
  # my-config = {
  #   # Enable custom gnome desktop on exampleHost
  #   template.desktop.gnome.enable = true;
  # };
}
