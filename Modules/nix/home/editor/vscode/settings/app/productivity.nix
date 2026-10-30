_: {
  extensions = [
    #? Better Todo Tree leverages ripgrep to locate custom tags like TODO and FIXME across your workspace. Results are mapped into a dedicated tree view and highlighted directly within your open files. Click any node in the tree to snap your cursor straight to that line of code..
    "FanaticPythoner.better-todo-tree"
    # #? Keyboard-driven file browser
    # "bodil.file-browser"
    #? Sort workspace folders alphabetically
    "iciclesoft.workspacesort"
    #? Diff two folders side by side
    "moshfeu.compare-folders"
    #? Multi-workspace file search
    "joshmu.periscope"
    #? Text transformation utilities
    "dakara.transformer"
    #? Convert case (camel, snake, kebab…)
    "wmaurer.change-case"
    #? Sort selected lines
    "tyriar.sort-lines"
    #? .env file support
    "dotenv.dotenv-vscode"
    # #? Restore familiar Windows keybindings
    # "smcpeak.default-keys-windows"
    #? Spreadsheet editing in VS Code
    "mescius.spreadjs-xlsx-editor"
  ];

  keybindings = [
    {
      key = "ctrl+alt+9";
      command = "sortLines.sortLinesCaseInsensitive";
      when = "editorTextFocus && !editorReadonly";
    }
  ];

  settings = {
    #~@ TODO Tree
    better-todo-tree.general = {
      #> Set polling interval (seconds) for tree refresh after repository changes.
      #? 0 disables
      automaticGitRefreshInterval = 0;
      #> Create a debug channel in the Output view
      debug = false;
      #> Export path; env vars like ${HOME} are expanded and strftime applies. A .json extension exports as a JSON record
      exportPath = "~/better-todo-tree-%Y%m%d-%H%M.txt";
      #> Set periodic tree refresh interval (minutes);
      #? 0 disables
      periodicRefreshInterval = 0;
      #> Cursor position when revealing a todo: "start of line", "start of todo" or "end of todo"
      revealBehaviour = "start of todo";
      #? Folder to run the search in; empty means the workspace folder
      rootFolder = "";
      #? Editor schemes to scan; add vscode-userdata for settings files or output for output windows
      schemes = [
        "file"
        "ssh"
        "untitled"
        "vscode-notebook-cell"
      ];
      #? Show a badge in the activity bar with the total number of TODOs
      showActivityBarBadge = false;
      #? Show icons instead of tags in the status bar
      showIconsInsteadOfTagsInStatusBar = false;
      #? Scanning progress display: none, status bar, notification, tree or all
      showScanningProgress = "status bar";
      #? Status bar content: none, total, tags, top three or current file
      statusBar = "none";
      #? Status bar click action: cycle, reveal or toggle highlights
      statusBarClickBehaviour = "reveal";

      #> Object-valued setting: keep as a real attrset, do not flatten
      #? Group similar tags under one type, e.g. { FIX = ["FIXME" "FIXIT"]; }; every tag must also be in tags
      tagGroups = {};

      #? Tag list; if one tag starts with another, list the longer one first
      tags = [
        "BUG"
        "HACK"
        "FIXME"
        "TODO"
        "XXX"
        "[ ]"
        "[x]"
      ];
    };

    #~@ Office
    spreadjs = {
      ribbonMode = "toolbar";
    };
  };
}
