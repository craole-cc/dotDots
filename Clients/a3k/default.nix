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
        enable = false;
        authorizedKeys = [];
      };
    };
    networking = {
      hostName = "a3k";
      timeZone = "America/Jamaica";
      hostId = "2c4a22f0";
    };
    Home.craole = {
      templates.desktop.enable = true;
      modules = {
        # firefox.enable = true;
        # home-manager.enable = true;
        # keyboard.enable = true;
        # tex.enable = true;
      };
    };
  };
}
