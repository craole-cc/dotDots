_: {
  keybindings = [
    {
      key = "ctrl+shift+s";
      command = "workbench.action.files.saveAll";
    }
    {
      key = "ctrl+`";
      command = "workbench.action.terminal.toggleTerminal";
    }
    {
      key = "ctrl+1";
      command = "workbench.action.focusFirstEditorGroup";
    }
    {
      key = "ctrl+2";
      command = "workbench.action.focusSecondEditorGroup";
    }

    {
      key = "ctrl+c";
      command = "editor.action.clipboardCopyAction";
      when = "textInputFocus";
    }
    {
      key = "ctrl+t ctrl+m";
      command = "workbench.action.toggleMaximizedPanel";
    }
    {
      key = "ctrl+shift+;";
      command = "workbench.action.openSettingsJson";
    }
    {
      key = "ctrl+alt+;";
      command = "workbench.action.openGlobalKeybindingsFile";
    }
    {
      key = "ctrl+alt+.";
      command = "extension.toggleFiles";
    }
    {
      key = "alt+down";
      command = "editor.action.moveLinesDownAction";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "alt+up";
      command = "editor.action.moveLinesUpAction";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "shift+f9";
      command = "sortLines.sortLinesCaseInsensitive";
    }
  ];
}
