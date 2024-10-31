{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:
let
  _mod = "hyprland";
in
{

  options = _args: {
    "${_mod}" =
      let
        _opt = _args.user.applications."${_mod}";
        _cfg = _args.user;
        inherit (lib.options) mkOption mkEnableOption mkPackageOption;
        inherit (lib.lists) any elem;
        inherit (lib.types)
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

        enable = mkEnableOption "Hyprland wayland compositor" // {
          default = _cfg.desktop.manager == "hyprland";
        };

        package = mkPackageOption pkgs "${_mod}" { };

        plugins = mkOption {
          description = "The Hyprland plugins to use";
          default = import ./plugins.nix;
          type = with lib.types; listOf (either package path);
        };

        settings = mkOption {
          description = "The Hyprland settings to use";
          default = import ./settings.nix { inherit (_args) host user; };
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
          default = import ./bindings.nix {
            inherit (_args.user) applications;
            inherit (_opt) workspaces directions;
          };
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
          default = import ./input.nix { inherit (_args) user; };
          type = attrsOf attrs;
        };

        variables = mkOption {
          description = "Environment variables";
          default = import ./environment.nix { inherit (_args) host user; };
          type = listOf str;
        };

        export = mkOption {
          default =
            with _opt;
            if enable then
              {
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
              }
            else
              { };
        };
      };
  };
}
