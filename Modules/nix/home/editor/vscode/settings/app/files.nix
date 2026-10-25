_: {
  name = "files";
  description = "File Management";

  extensions = [
    #? Toggle settings in Visual Studio Code
    "rebornix.toggle"
  ];

  keybindings = [
    {
      key = "ctrl+shift+,";
      command = "-editor.action.inPlaceReplace.up";
      when = "editorTextFocus && !editorReadonly";
    }
    {
      key = "ctrl+shift+,";
      command = "workbench.action.openSettingsJson";
    }
    {
      key = "ctrl+shift+alt+,";
      command = "runCommands";
      args = {
        "commands" = [
          "workbench.action.openSettingsJson"
          "workbench.action.openRawDefaultSettings"
          "workbench.action.moveEditorToNextGroup"
        ];
      };
    }
    {
      key = "ctrl+alt+,";
      command = "workbench.action.openGlobalKeybindingsFile";
    }
    {
      key = "shift+alt+,";
      command = "runCommands";
      args = {
        "commands" = [
          "workbench.action.openDefaultKeybindingsFile"
          "workbench.action.openGlobalKeybindingsFile"
          "workbench.action.moveEditorToNextGroup"
        ];
      };
    }
    {
      key = "ctrl+alt+.";
      command = "extension.toggleFiles";
    }
  ];

  settings = {
    explorer = {
      #> Show single-child folder chains as one compact entry
      compactFolders = false;
      #> Hide files matched by .gitignore in the explorer
      excludeGitIgnore = false;
    };

    files = {
      eol = "\n";

      #> Save when the editor loses focus
      autoSave = "afterDelay";
      #> Ensure files end with a newline on save
      insertFinalNewline = true;
      #> Remove extra trailing newlines at the end of the file on save
      trimFinalNewlines = true;
      #> Remove trailing whitespace on save
      trimTrailingWhitespace = true;

      #> Object-valued settings below: glob keys must stay as-is, do not flatten
      #? Hide patterns in the explorer; false entries override the defaults so these stay visible
      exclude = {
        "**/.DS_Store" = false;
        "**/.git" = false;
        "**/.hg" = false;
        "**/.svn" = false;
        "**/Thumbs.db" = false;
      };

      #> Verify these globs: some look mangled (stray spaces, missing trailing **)
      #? Paths the file watcher ignores
      watcherExclude = {
        "**/.local/* *" = true;
        "**/.vscode-server-insiders/* *" = true;
        "**/* cache/* *" = true;
        "**/.trunk/*actions/" = true;
        "**/.trunk/*logs/" = true;
        "**/.trunk/*notifications/" = true;
        "**/.trunk/*out/" = true;
        "**/.trunk/*plugins/" = true;
      };

      #? Glob to language ID mapping
      associations = {
        ".bash*" = "shellscript";
        ".dotsrc" = "coffeescript";
        ".editorconfig" = "ini";
        ".env" = "env";
        ".env*" = "dotenv";
        ".sqruff" = "properties";
        "**/*.conf" = "ini";
        "**/conf*/{fuzzel,ghostty,mpv,hyprland}/*" = "ini";
        "**/conf*/{raffi}/*" = "yaml";
        "*.Xresources" = "xdefaults";
        "*envrc" = "shellscript";
        "*gitignore" = "ignore";
        "*ignore" = "ignore";
        "*shellcheckrc" = "shellscript";
        "editorconfig" = "ini";
        "flake.lock" = "json";
        "i3/*.conf" = "i3";
        "i3/config" = "i3";
        "lesskey" = "lesskey";
        "mise.lock" = "toml";
        "polybar/*.conf" = "ini";
        "polybar/config" = "ini";
        "*.bash" = "shellscript";
        "*.css" = "css";
        "*.erb" = "ruby";
        "*.ft" = "rust";
        "*.gs" = "javascript";
        "*.init" = "shellscript";
        "*.nix" = "nix";
        "*.nu" = "nushell";
        "*.rs" = "rust";
        "*.sh" = "shellscript";
        "*.typ" = "typst";
        "Gemfile" = "ruby";
        "*.bbmodel" = "json";
        "*.ejs" = "html";
        "*.emu" = "html";
        "*.hbs" = "html";
        "*.layout" = "json";
        "*.log" = "log";
        "*.rasi" = "css";
        "*.sublime-snippet" = "xml";
        "LICENSE" = "txt";
        "LICENSE-MIT" = "txt";
        "README" = "markdown";
      };
    };

    #> Object-valued setting: keep as a real attrset, do not flatten
    #? Glob to custom editor mapping; "default" uses the normal text editor
    workbench.editorAssociations = {
      "*.copilotmd" = "vscode.markdown.preview.editor";
      "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.qrc" = "default";
      "{git,gitlens,chat-editing-snapshot-text-model,copilot,git-graph,git-graph-3}:/**/*.ui" = "default";
      "*.db" = "default";
      # "*.pdf" = "pdf.view";
      # "*.qrc" = "qt-core.qrcEditor";
      # "*.tsv" = "csvViewer.csvEditor";
      # "*.xlsx" = "csvViewer.csvEditor";
    };
  };
}
