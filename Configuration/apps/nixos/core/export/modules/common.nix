{
  specialArgs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (specialArgs) host;
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
    inherit (host.location) defaultLocale;
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  location = {
    inherit (host.location) latitude longitude;
    provider =
      with config.location;
      if latitude == null || longitude == null then "geoclue2" else "manual";
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
        "craole"
        # TODO: all hosts.people.name
      ];
    };
  };

  powerManagement = {
    cpuFreqGovernor = host.cpu.mode or "performance";
    powertop.enable = true;
  };

  time = {
    inherit (host.location) timeZone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };

  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [
            "craole"
            # TODO: all hosts.people.name that isElevated = true
          ];
          commands = [
            {
              command = "ALL";
              options = [
                "SETENV"
                "NOPASSWD"
              ];
            }
          ];
        }
      ];
    };
  };
}
