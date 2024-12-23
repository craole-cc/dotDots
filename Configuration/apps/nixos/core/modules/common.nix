{
  specialArgs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs) host users;
  inherit (host) cpu stateVersion system;
  inherit (host.location)
    latitude
    longitude
    defaultLocale
    timeZone
    ;
  inherit (lib.attrsets) attrNames filterAttrs;

  userList = attrNames users;
  adminList = attrNames (filterAttrs (_: user: user.isAdminUser or false) users);
in
{
  console = {
    # TODO use specialArgs
    packages = [ pkgs.terminus_font ];
    font = "ter-u28n";
    earlySetup = true;
    useXkbConfig = true;
  };

  i18n = {
    inherit defaultLocale;
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  location = {
    inherit latitude longitude;
    provider = if latitude == null || longitude == null then "geoclue2" else "manual";
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ] ++ userList;
    };
  };

  nixpkgs = {
    hostPlatform = system;
  };

  powerManagement = {
    cpuFreqGovernor = cpu.mode or "performance";
    powertop.enable = true;
  };

  time = {
    inherit timeZone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };

  # security = {
  #   sudo = {
  #     execWheelOnly = true;
  #     extraRules = [
  #       {
  #         users = adminList;
  #         commands = [
  #           {
  #             command = "ALL";
  #             options = [
  #               "SETENV"
  #               "NOPASSWD"
  #             ];
  #           }
  #         ];
  #       }
  #     ];
  #   };
  # };

  system = { inherit stateVersion; };
}
