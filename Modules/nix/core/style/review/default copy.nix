# {
#   config,
#   lib,
#   lix,
#   tree,
#   pkgs,
#   top,
#   ...
# }: let
#   inherit (lix.filesystem.importers) importAllPaths;
#   inherit (lix.modules.core.style) mkStyle;
#   dom = "interface";
#   mod = "style";
#   cfg = config.${top}.${dom}.${mod};
#   inherit
#     (cfg)
#     cursors
#     fonts
#     icons
#     themes
#     wallpapers
#     ;
#   inherit (lib.modules) mkIf mkMerge;
#   inherit (lib.options) literalExpression mkEnableOption mkOption;
#   inherit (lib.types) enum bool;
# in {
#   imports = importAllPaths ./.;
#   options.${top}.${dom}.${mod} = {
#     enable = mkEnableOption mod // {default = true;};
#     polarity = mkOption {
#       description = ''
#         Active color polarity. Flips theme, cursor, wallpaper, icons, and opacity atomically.
#         All resolved sub-options (theme.resolved, cursors.resolved, ...) expose both polarities;
#         this option selects which one is applied by mkStyle and written to THEME_POLARITY.
#       '';
#       default = "dark";
#       defaultText = literalExpression ''"dark"'';
#       type = enum ["light" "dark"];
#     };
#     enableStylix = mkOption {
#       description = "Wire resolved style data into Stylix. When false, only fonts and session variables are emitted.";
#       default = false;
#       defaultText = literalExpression "false";
#       type = bool;
#     };
#   };
#   config = mkIf cfg.enable (
#     mkMerge [
#       (mkStyle {
#         inherit pkgs;
#         inherit (lix) tree;
#         inherit (cfg) polarity enableStylix;
#         # fonts = cfg.fonts.resolved or (lix.modules.core.style.resolveFonts {inherit pkgs;});
#         # wallpapers = cfg.wallpapers.resolved or (lix.modules.core.style.resolveWallpapers {inherit (lix) tree;});
#         # theme = cfg.theme.resolved or (lix.modules.core.style.resolveThemes {inherit pkgs;});
#         # cursors = cfg.cursors.resolved or (lix.modules.core.style.resolveCursors {inherit pkgs;});
#         # icons = cfg.icons.resolved or (lix.modules.core.style.resolveIcons {inherit pkgs;});
#         # opacity = cfg.opacity.resolved or (lix.modules.core.style.resolveOpacity {});
#       })
#     ]
#   );
# }
{}
