{
  config,
  lib,
  modulesPath,
  ...
}: let
  inherit (lib.modules) mkDefault;
in {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.kernelModules = ["kvm-intel"];
  hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
  networking = {
    # The source hardware configuration enables NetworkManager but does not
    # record stable interface names, so do not invent any here.
    hostName = mkDefault "Preci";
    hostId = mkDefault "cfd69003";
    networkmanager.enable = true;
  };
}
