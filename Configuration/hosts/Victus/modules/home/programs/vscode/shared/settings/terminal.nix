{
  programs.vscode.profiles.default.userSettings = {
    "terminal.integrated.fontSize" = 18;
    "terminal.integrated.fontWeight" = 500;
    "terminal.integrated.fontLigatures.enabled" = true;
    "terminal.integrated.letterSpacing" = 0;
    "terminal.integrated.lineHeight" = 1.2;

    "terminal.integrated.allowMnemonics" = true;
    "terminal.integrated.commandsToSkipShell" = [
      "workbench.action.terminal.copySelection"
    ];
    "terminal.integrated.confirmOnExit" = "never";
    "terminal.integrated.copyOnSelection" = true;
    "terminal.integrated.cursorBlinking" = true;
    "terminal.integrated.cursorStyle" = "block";
    "terminal.integrated.enableImages" = true;
    "terminal.integrated.enableMultiLinePasteWarning" = "never";
    "terminal.integrated.hideOnStartup" = "whenEmpty";
    "terminal.integrated.mouseWheelZoom" = false;
    "terminal.integrated.rightClickBehavior" = "copyPaste";
    "terminal.integrated.smoothScrolling" = true;

    # Linux default profile
    # "terminal.integrated.defaultProfile.linux" = "nushell";
  };
}
