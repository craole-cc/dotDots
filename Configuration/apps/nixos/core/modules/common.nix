{
  specialArgs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs) host users;
  inherit (specialArgs.host) cpu;
  # inherit (host.location)
  #   latitude
  #   longitude
  #   defaultLocale
  #   timeZone
  #   ;
  # inherit (lib.attrsets) attrNames filterAttrs;

in
# userList = attrNames users;
# adminList = attrNames (filterAttrs (_: user: user.isAdminUser or false) users);
{
  console = {
    # TODO use specialArgs
    packages = [ pkgs.terminus_font ];
    font = "ter-u28n";
    earlySetup = true;
    useXkbConfig = true;
  };

  # i18n = {
  #   inherit defaultLocale;
  # };

  # location = {
  #   inherit latitude longitude;
  #   provider = if latitude == null || longitude == null then "geoclue2" else "manual";
  # };

  powerManagement = {
    cpuFreqGovernor = cpu.mode or "performance";
    powertop.enable = true;
  };

  # time = {
  #   inherit timeZone;
  #   hardwareClockInLocalTime = lib.mkDefault true;
  # };
}
