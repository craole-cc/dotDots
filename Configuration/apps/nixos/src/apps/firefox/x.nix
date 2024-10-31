{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str nullOr enum;
in

{
  options.dot.applications.firefox = with config.dot.applications.firefox; {
    enable = mkEnableOption "Enable Firefox";

    edition = mkOption {
      type = nullOr (enum [
        "main"
        "dev"
        "esr"
        "beta"
        "floorp"
        "librewolf"
      ]);
      default = null;
      description = "Firefox edition to use.";
    };

    name = mkOption {
      description = "Name of the application";
      default =
        if edition == "dev" then
          "Firefox [Developer Edition]"
        else if edition == "esr" then
          "Firefox [Extended Support Release]"
        else if edition == "beta" then
          "Fiirefox [Beta]"
        else if edition == "floorp" then
          "Floorp"
        else if edition == "librewolf" then
          "LibreWolf"
        else
          "Firefox";
    };

    package = mkOption {
      description = "Package to use for Firefox";
      default =
        with pkgs;
        if edition == "dev" then
          firefox-devedition-bin
        else if edition == "esr" then
          firefox-esr
        else if edition == "beta" then
          firefox-beta-bin
        else if edition == "floorp" then
          floorp
        else if edition == "librewolf" then
          librewolf
        else
          firefox;
      type = package;
    };

    command = mkOption {
      description = "Command to use for Firefox";
      default =
        if edition == "dev" then
          "firefox-developer-edition"
        else if edition == "esr" then
          "firefox-esr"
        else if edition == "beta" then
          "firefox-beta"
        else if edition == "floorp" then
          "floorp"
        else if edition == "librewolf" then
          "librewolf"
        else
          "firefox";
      type = str;
    };

    export = mkOption { default = if enable then { inherit enable package; } else { }; };
  };
}
