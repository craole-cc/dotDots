{
  context,
  mkEnable,
  ...
}: let
  mod = "context";
  condition = true;
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = [
    #? Cherry-pick workspace files as XML payloads for LLM prompts.
    "airizom.context-craft"
    #? Scans folders to generate file data or a tree structure.
    "shinazbinshajahan.fileinator"
    #? Dump selected files/folders to Markdown, or load them back.
    "NixFractal.md-file-dumper"
  ];

  keybindings = [
    #> Copy the selected Context Craft files/selection as a prompt payload.
    {
      key = "ctrl+alt+c";
      command = "contextCraft.copySelected";
      when = "editorTextFocus || focusedView == 'contextCraftFileBrowser'";
    }
    #> Pre-select all files with uncommitted git changes.
    {
      key = "ctrl+alt+g";
      command = "contextCraft.selectGitChanges";
      when = "focusedView == 'contextCraftFileBrowser'";
    }
    #> Pre-select all currently open editors.
    {
      key = "ctrl+alt+o";
      command = "contextCraft.selectOpenEditors";
      when = "focusedView == 'contextCraftFileBrowser'";
    }
    #> Clear the selection.
    {
      key = "ctrl+alt+u";
      command = "contextCraft.unselectAll";
      when = "focusedView == 'contextCraftFileBrowser'";
    }
  ];

  settings = {
    copyContext = {
      copyContent = {
        #~@ context-craft
        #> Excludes scoped to "Copy Content" only. Merged with global excludes.
        excludeGlobs = [];
        #> Includes scoped to "Copy Content" only. Merged with global includes.
        includeGlobs = [];
      };

      copyTree = {
        #> Excludes scoped to "Copy Tree" only. Merged with global excludes.
        excludeGlobs = [];
        #> Includes scoped to "Copy Tree" only. Merged with global includes.
        includeGlobs = [];
      };

      #> Global excludes applied to all commands. Highest priority;
      #> command-specific excludes are merged on top.
      excludeGlobs = [];
      #> Global includes applied to all commands. Command-specific
      #> includes are merged on top.
      includeGlobs = [];

      #> Maximum total size (bytes) of all copied file contents. Prevents
      #> dumping very large files into your prompt.
      maxContentSize = 500000;

      #> Skip files matching the project's `.gitignore` (opt-in).
      #! overridden (default: false)
      respectGitIgnore = true;

      #> Skip files/folders hidden in the VS Code Explorer (respects
      #> `files.exclude`).
      respectVSCodeExplorerExclude = true;

      #> Additional file extensions to treat as text (without the dot).
      #? Useful for custom or newer file types not recognised by default.
      #? Example: `["zmodel", "prisma"]`
      additionalTextExtensions = [];

      #> Include emojis in the output (📁 for folders, 📄 for files).
      #! overridden (default: false)
      includeEmojis = false;

      #> Place the file path above the fenced code block instead of inside
      #? it. Applies to Copy Content & Copy Selection only; Copy Tree
      #? always keeps paths inside.
      pathOutsideCodeBlock = false;
    };

    #~@ fileinator
    #> Folder paths (relative to workspace root) to ignore in scans.
    fileinator.ignoredFolders = [];

    mdFileDumper = {
      binary = {
        #~@ md-file-dumper
        #? Namespaced `mdFileDumper.*`. Flat registration — do not nest.

        #> Extensions to always treat as binary (regardless of content).
        forceAsBin = [];
        #> Extensions to block from binary handling.
        blockedTypes = [];
        #> How binary files are encoded in the dump.
        #?  - base64_zip: base64 + zip payload
        #?  - base64:     base64 only
        #?  - skip:       omit binary files entirely
        format = "base64_zip";
        #> Maximum binary file size to include (KB).
        maxSizeKb = 1024;
        #> How to handle binary files during dump.
        #?  - allow:     include (with encoding per `format`)
        #?  - forbid:    exclude binary files
        #?  - ask:       prompt
        mode = "allow";
      };

      files = {
        #> Allowed file extensions for the dump (empty = all).
        allowedTypes = [];
        #> Blocked file extensions for the dump (glob patterns supported).
        #?  Empty = none.
        blockedTypes = [
          "**/*.{pyc,pyo,pyd,swp,swo,lock,bak,tmp,temp}"
          "**/.git/**"
          "**/.venv/**"
          "**/.env/**"
          "**/node_modules/**"
          "**/__pycache__/**"
          "**/.pytest_cache/**"
          "**/.mypy_cache/**"
          "**/.ruff_cache/**"
          "**/.cache/**"
          "**/Thumbs.db"
        ];
      };

      #> Prefix used for file headers in the dump.
      prefix = "##";
      #> Show "Export/Import to File" command in the menu.
      showImportExportToFile = false;
    };
  };
in {inherit enable extensions keybindings options settings;}
