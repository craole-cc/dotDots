{ ... }: {
  services.upower.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
}
