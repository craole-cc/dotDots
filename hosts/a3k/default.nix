# #
##
##  per-host configuration for exampleHost
##
##

{ system, pkgs, ... }: {
  inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [  "nvme-HFM256GDJTNG-8310A_CY9CN00281150CJ46" ];
      immutable = false;
      availableKernelModules = [  "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      removableEfi = true;
      kernelParams = [ ];
      sshUnlock = {
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      hostName = "a3k";
      timeZone = "America/Jamaica";
      hostId = "18767976453";
    };
    per-user.craole = {
      templates.desktop.enable = true;
      modules.keyboard.enable = true;
    };
  };
}
