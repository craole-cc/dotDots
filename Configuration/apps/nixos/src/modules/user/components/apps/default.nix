{ ARGS, ... }:
{

  bat = import ./bat { inherit ARGS; };
  btop = import ./btop { inherit ARGS; };
  dunst = import ./dunst { inherit ARGS; };
  firefox = import ./firefox { inherit ARGS; };
  # git = import ./git { inherit ARGS; };
  # helix = import ./helix { inherit ARGS; };
  # rofi = import ./rofi { inherit ARGS; };
  # hyprland = import ./hyprland { inherit ARGS; };
  # microsoft = import ./microsoft { inherit ARGS; };
  # waybar = import ./waybar { inherit ARGS; };

  #   programs = mkOption {
  #     default = with applications; {
  #       # bat = bat.export;
  #       # btop = btop.export;
  #       # firefox = firefox.export;
  #       # git = git.export;
  #       # helix = helix.export;
  #       # rofi = rofi.export;
  #     };
  #   };

  #   packages = mkOption {
  #     default = with applications; {
  #       # bat = bat.export.package;
  #       # btop = btop.export.package;
  #       # firefox = firefox.export.package;
  #       # git = git.export.package;
  #       # helix = helix.export.package;
  #       # rofi = rofi.export.package;
  #     };
  #   };

  #   launcher = {
  #     modifier = mkOption {
  #       description = "Modifier key for window managers";
  #       default = "SUPER";
  #       type = str;
  #     };
  #     primary = {
  #       name = mkOption {
  #         type = str;
  #         default = "rofi";
  #         description = "Launcher name";
  #       };
  #       package = mkOption {
  #         description = "Package name";
  #         default = pkgs.rofi;
  #         type = package;
  #       };
  #       command = mkOption {
  #         type = str;
  #         default = "rofi -show-icons -show drun";
  #         description = "Launcher command";
  #       };
  #     };
  #     secondary = {
  #       name = mkOption {
  #         description = "Secondary launcher name";
  #         default = "anyrun";
  #         type = str;
  #       };
  #       command = mkOption {
  #         description = "Secondary launcher command";
  #         default = "anyrun";
  #         type = str;
  #       };
  #     };
  #   };

  #   terminal = {
  #     primary = {
  #       name = mkOption {
  #         description = "Terminal name";
  #         default = "foot";
  #         type = str;
  #       };

  #       package = mkPackageOption pkgs "foot" { };

  #       command = mkOption {
  #         description = "Launcher command";
  #         default = "footclient";
  #         type = str;
  #       };
  #     };
  #     secondary = {
  #       name = mkOption {
  #         description = "Terminal name";
  #         default = "warp-terminal";
  #         type = str;
  #       };

  #       package = mkPackageOption pkgs "warp-terminal" { };

  #       command = mkOption {
  #         description = "Terminal command";
  #         type = str;
  #         default = "warp-terminal";
  #       };
  #     };
  #   };

  #   editor = {
  #     primary = {
  #       name = mkOption {
  #         description = "Editor name";
  #         default = "Editor";
  #         type = str;
  #       };

  #       package = mkPackageOption pkgs "helix" { };

  #       command = mkOption {
  #         description = "Editor command";
  #         type = str;
  #         default = "ede";
  #       };
  #     };

  #     secondary = {
  #       name = mkOption {
  #         type = str;
  #         default = "code";
  #         description = "Editor name";
  #       };

  #       package = mkPackageOption pkgs "vscode-fhs" { };

  #       command = mkOption {
  #         description = "Launcher command";
  #         type = str;
  #         default = "code";
  #       };
  #     };
  #   };

  #   browser = {
  #     primary = {
  #       name = mkOption {
  #         type = str;
  #         default = "firefox-bin";
  #         description = "Launcher name";
  #       };

  #       package = mkPackageOption pkgs "firefox-devedition-bin" { };

  #       command = mkOption {
  #         type = str;
  #         default = "firefox-developer-edition";
  #         description = "Launcher command";
  #       };
  #     };

  #     secondary = {
  #       name = mkOption {
  #         type = str;
  #         default = "Microsoft Edge";
  #         description = "Secondary Browser";
  #       };

  #       package = mkPackageOption pkgs "microsoft-edge-dev" { };

  #       command = mkOption {
  #         type = str;
  #         default = "microsoft-edge-dev";
  #         description = "Secondary Browser";
  #       };
  #     };
  #   };

  #   shell = mkOption {
  #     description = "The user's shell";
  #     default = null;
  #     type = nullOr (either shellPackage (passwdEntry path));
  #   };
}
