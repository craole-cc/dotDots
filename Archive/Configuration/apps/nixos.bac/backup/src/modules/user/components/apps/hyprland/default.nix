{ ARGS, ... }:
let
  inherit (ARGS)
    pkgs
    lib
    USER
    LIBS
    ;

  _mod = "hyprland";
  _user = USER.name;
  _top = USER.apps;
  _cfg = _top."${_mod}";

  inherit (lib) types;
  inherit (lib.options) mkOption mkEnableOption mkPackageOption;
  inherit (lib.lists) any elem;
  inherit (types)
    nullOr
    str
    attrs
    listOf
    either
    attrsOf
    list
    path
    ;
in
{
  options.DOTS.apps.${_mod} = with config.DOTS.apps."${_mod}"; {

    enable = mkEnableOption "Hyprland wayland compositor";

    package = mkPackageOption pkgs "${_mod}" { };

    packages = mkOption {
      description = "The nix packages to install";
      default = import ./packages.nix { inherit pkgs; };
      type = with types; listOf (either package path);
    };

    plugins = mkOption {
      description = "The Hyprland plugins to use";
      default = import ./plugins.nix { inherit pkgs; };
      type = with types; listOf (either package path);
    };

    settings = mkOption {
      description = "The Hyprland settings to use";
      default = import ./settings.nix;
      type = attrsOf (either attrs list);
    };

    systemd = mkOption {
      description = "The Hyprland settings to use";
      default = {
        enable = true;
        variables = [ "-all" ];
        extraCommands = [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };
      type = attrs;
    };

    bindings = mkOption {
      default = import ./bindings.nix { inherit workspaces directions; };
      type = attrs;
    };

    workspaces = mkOption {
      default = [
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
        "F1"
        "F2"
        "F3"
        "F4"
        "F5"
        "F6"
        "F7"
        "F8"
        "F9"
        "F10"
        "F11"
        "F12"
      ];
      type = listOf str;
    };

    directions = mkOption {
      description = "Map keys to hyprland directions  (l, r, u, d)";
      default = {
        left = "l";
        right = "r";
        up = "u";
        down = "d";
        h = "l";
        l = "r";
        k = "u";
        j = "d";
      };
      type = attrs;
    };

    autorun = mkOption {
      description = "Applications to run on startup";
      default = import ./autorun.nix;
      type = listOf str;
    };

    input = mkOption {
      description = "Variables related to input devices";
      default = import ./input.nix;
      type = attrsOf attrs;
    };

    variables = mkOption {
      description = "Environment variables";
      default = import ./environment.nix;
      type = listOf str;
    };
  };
  # export = {
  config = {
    home-manager.users.${_user} = {
      wayland.windowManager.hyprland = mkOption {
        default = {
          inherit
            enable
            package
            plugins
            systemd
            ;
          settings =
            settings
            // {
              env = variables;
              exec-once = autorun;
              inherit input;
            }
            // bindings;
        };
        type = attrs;
      };
      home.packages = packages;
      # home.packages = mkOption { default = packages; };
    };
  };
}
