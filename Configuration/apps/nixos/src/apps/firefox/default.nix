{
  config,
  pkgs,
  lib,
  ...
}:
let
  _mod = "firefox";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.lists) any elem;
  inherit (lib.types)
    attrs
    str
    enum
    path
    ;
  inherit (lib.strings) hasPrefix toLower replaceStrings;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "${_mod}";

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
      type = lib.types.package;
    };

    isPrimary = mkEnableOption "${_mod}";
    isSecondary = mkEnableOption "${_mod}";

    edition = mkOption {
      description = "Firefox edition to use.";
      default = "main";
      type = enum [
        "main"
        "dev"
        "esr"
        "beta"
        "floorp"
        "librewolf"
      ];
    };

    name = mkOption {
      description = "Name of the application";
      default =
        let
          inherit (command) name;

          replaceHyphenSpace = lib.strings.replaceStrings [ "-" ] [ " " ] name;
          transformedName = toLower replaceHyphenSpace;
        in
        transformedName;
      type = str;
    };

    command = with command; {
      bin = mkOption {
        description = "Command to use for Firefox";
        default = package.outPath + "/bin/${name}";
        type = path;
      };

      name = mkOption {
        description = "Command to use for Firefox";
        default = package.meta.mainProgram;
        type = str;
      };

      kill = mkOption {
        description = "Command to kill Firefox";
        default = ''pkill --full ${bin}'';
      };

      toggle = mkOption {
        description = "Command to reload Firefox";
        default = ''${kill} || ${bin}'';
      };

      # raise = mkOption {
      #   description = "Command to raise Firefox";
      #   default = if desktop.manager == "hyprland" then ''hyprctl
      # }
    };

    export = mkOption {
      default = {
        inherit enable package;
      };
      type = attrs;
    };
  };
}
