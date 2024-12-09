{
  specialArgs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}:
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        specialArgs.alpha
        "@wheel"
      ];
    };
  };

  time = {
    inherit (specialArgs.location) timeZone;
    hardwareClockInLocalTime = lib.mkDefault true;
  };

  location = {
    inherit (specialArgs.location) latitude longitude;
    provider =
      with config.location;
      if latitude == null || longitude == null then "geoclue2" else "manual";
  };

  i18n = {
    inherit (specialArgs.location) defaultLocale;
  };

  console = {
    # TODO use specialArgs
    packages = [ pkgs.terminus_font ];
    font = "ter-u32n";
    earlySetup = true;
    useXkbConfig = true;
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
