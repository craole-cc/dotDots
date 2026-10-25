{style, ...}: {
  name = "transparency";
  description = "Window transparency using the user API opacity";
  extensions = ["illixion.vscode-vibrancy-continued"];

  settings.vscode_vibrancy = {
    type = "transparent";
    windowMode = "frameless-transparent";
    opacity = style.opacity.terminal.${style.mode};
  };
}
