{
  specialArgs,
  lib,
  pkgs,
  ...
}:
let
  inherit (specialArgs) host users;
  inherit (specialArgs.host) cpu;

in
{
  console = {
    # TODO use specialArgs
    packages = [ pkgs.terminus_font ];
    font = "ter-u28n"; # TODO: this should be based on the screen size
    earlySetup = true;
    useXkbConfig = true;
  };

  powerManagement = {
    cpuFreqGovernor = cpu.mode or "performance";
    powertop.enable = true;
  };
}
