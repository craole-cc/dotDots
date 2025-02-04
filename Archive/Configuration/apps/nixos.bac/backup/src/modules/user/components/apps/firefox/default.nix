{ ARGS, ... }:
let
  inherit (ARGS)
    pkgs
    lib
    USER
    LIBS
    ;

  _mod = "firefox";
  _top = USER.apps;
  _cfg = _top."${_mod}";

  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.types)
    attrs
    str
    enum
    path
    ;
  inherit (lib.lists) any elem;
  inherit (lib.strings) hasPrefix toLower replaceStrings;

  inherit (USER) isMinimal context;
  inherit (LIBS.filesystem) nullOrpathof pathof;
in
with _cfg;
{
  enable = mkEnableOption "${_mod}" // {
    default = isPrimary || isSecondary;
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
    type = lib.types.package;
  };

  isPrimary = mkEnableOption "${_mod}" // {
    default = !isMinimal;
  };
  isSecondary = mkEnableOption "${_mod}";

  edition = mkOption {
    description = "Firefox edition to use.";
    default = if elem "development" context then "dev" else "main";
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
    default = with _cfg; if enable then { inherit enable package; } else { };
    type = attrs;
  };

  test = mkOption { default = context; };
}
