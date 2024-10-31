{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) elem;
  inherit (lib.types)
    str
    nullOr
    enum
    package
    ;
  inherit (lib.attrsets) mapAttrs filterAttrs;
  inherit (config.dot) users applications active;

  inherit (active) user host;
  app = config.dot.applications.firefox;

  userConfig =
    with user;
    mkIf (enable && (elem name (map (u: u.name) host.people))) {

      home-manager.users = mapAttrs (
        name: u: with u; {
          # gtk = {
          #   enable = true;
          #   font = fonts.gtk;
          #   iconTheme = icons.gtk;
          # };
          # home = {
          #   inherit
          #     packages
          #     sessionVariables
          #     shellAliases
          #     stateVersion
          #     ;
          # };
          # programs.firefox = applications.firefox.export;
        }
      ) (filterAttrs (_: u: (u.enable && u.isNormalUser)) users);
    };
in
{
  options.dot.applications.firefox = {
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
        with app;
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
        with app;
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
        with app;
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

    export = mkOption { default = with app; if enable then { inherit enable package; } else { }; };
  };

  options.test.firefox = mkOption { default = userConfig; };
  # config = {
  #   inherit home-manager;
  # };
}
