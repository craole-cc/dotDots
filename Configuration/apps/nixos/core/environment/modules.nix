{
  specialArgs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  console = {
    # TODO use specialArgs
    packages = [ pkgs.terminus_font ];
    font = "ter-u32n";
    earlySetup = true;
    useXkbConfig = true;
  };

  i18n = {
    inherit (specialArgs.location) defaultLocale;
  };

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  location = {
    inherit (specialArgs.location) latitude longitude;
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
        specialArgs.alpha
      ];
    };
  };

  powerManagement = {
    cpuFreqGovernor = "ondemand";
    powertop.enable = true;
  };

  time = {
    inherit (specialArgs.location) timeZone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };

  security = {
    sudo = {
      execWheelOnly = true;
      extraRules = [
        {
          users = [ specialArgs.alpha ];
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
    rtkit.enable = true;
  };
}
