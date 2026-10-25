{
  style,
  lix,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeSetting;
in {
  name = "transparency";
  description = "Desktop wallpaper behind editor surfaces using the user API opacity";
  extensions = ["subframe7536.custom-ui-style"];

  settings.custom-ui-style = {
    # Keep the native window opaque and text fully opaque. DMS supplies the
    # desktop wallpaper URL; only the colour overlay has reduced opacity.
    electron = mkVSCodeSetting {transparent = false;};
    background = {
      opacity = 1;
      size = "cover";
      position = "center";
    };
    stylesheet = mkVSCodeSetting {
      "body:has(div[role=application])" = {position = "relative";};
      ".monaco-workbench::before" = {
        content = "''";
        position = "fixed";
        inset = "0";
        "pointer-events" = "none";
        "background-color" = "var(--vscode-editor-background)";
        opacity = style.opacity.editor.${style.mode};
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
