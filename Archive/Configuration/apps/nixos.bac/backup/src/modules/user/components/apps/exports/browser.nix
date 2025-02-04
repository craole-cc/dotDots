{
  browser = {
    primary = {
      name = mkOption {
        type = str;
        default = "firefox-bin";
        description = "Launcher name";
      };

      package = mkPackageOption pkgs "firefox-devedition-bin" { };

      command = mkOption {
        type = str;
        default = "firefox-developer-edition";
        description = "Launcher command";
      };
    };

    secondary = {
      name = mkOption {
        type = str;
        default = "Microsoft Edge";
        description = "Secondary Browser";
      };

      package = mkPackageOption pkgs "microsoft-edge-dev" { };

      command = mkOption {
        type = str;
        default = "microsoft-edge-dev";
        description = "Secondary Browser";
      };
    };
  };
}
