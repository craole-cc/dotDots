{
  style,
  lix,
  pkgs,
  cfg,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeSetting;
  inherit (lix.lists.construction) optional;
  wallpaperScript = import ../../build/wallpaper-script.nix {inherit pkgs lix;};
in {
  name = "transparency";
  description = "Desktop wallpaper behind editor surfaces using the user API opacity";
  extensions = ["subframe7536.custom-ui-style"];

  settings.custom-ui-style = {
    # Keep the native window and text opaque. The renderer follows DMS's
    # retained wallpaper snapshot; only the colour overlay has lower opacity.
    electron = mkVSCodeSetting {transparent = false;};
    external.imports = optional (!(cfg.features.ui.animations or false)) "file://${wallpaperScript}";
    stylesheet = mkVSCodeSetting {
      "body:has(div[role=application])" = {position = "relative";};
      ".monaco-workbench::before" = {
        content = "''";
        position = "fixed";
        inset = "0";
        "pointer-events" = "none";
        "background-color" = "var(--vscode-editor-background)";
        opacity = "var(--dotdots-editor-opacity, ${toString style.opacity.editor.${style.mode}})";
        "z-index" = "-1";
      };
      ".monaco-workbench" = {
        position = "relative";
        isolation = "isolate";
        "z-index" = "1";
      };
      ".monaco-workbench, .monaco-workbench .part, .monaco-editor, .monaco-editor-background, .monaco-editor .margin, .monaco-workbench .editor-container" = {
        "background-color" = "transparent !important";
      };
    };
  };
}
