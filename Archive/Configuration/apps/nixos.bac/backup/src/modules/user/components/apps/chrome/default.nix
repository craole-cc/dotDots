{
  config,
  lib,
  pkgs,
  ...
}:
let
  program = "chrome";
  inherit (config) dots;

  cfg = dots.programs.${program};
  inherit (cfg) edition;
in
with lib;
with types;
{
  options.dots.programs.${program} = {
    enable = mkEnableOption "Enable Chrome-based Browser";

    edition = mkOption {
      type = enum [
        "chromium"
        "edge"
        "chrome"
      ];
      default = "edge";
      description = "Chrome-based browser to use.";
    };

    package = mkOption {
      description = "Package to use for the browser";
      default =
        with programs.chrome;
        with pkgs;
        if edition == "edge" then
          microsoft-edge-dev
        else if edition == "chrome" then
          google-chrome
        else
          chromium;
      type = package;
    };

    command = mkOption {
      description = "Command to use for the browser";
      default =
        with programs.chrome;
        if edition == "edge" then
          "microsoft-edge-dev"
        else if edition == "chrome" then
          "google-chrome-stable"
        else
          "chromium";
      type = str;
    };
  };

  config = mkIf cfg.enable {
    users.users.craole.packages = [ cfg.package ];
    # users.users.${dots.lib.currentUser}.packages = [ cfg.package ];

    # programs.chromium = mkIf (edition == "chromium") { inherit (cfg) enable package; };
  };
}
