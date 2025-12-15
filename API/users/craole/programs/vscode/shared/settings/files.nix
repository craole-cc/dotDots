{
  programs.vscode.profiles.default.userSettings = {
    "files.autoSave" = "afterDelay";
    "files.eol" = "\n";
    "files.insertFinalNewline" = true;
    "files.trimFinalNewlines" = true;
    "files.trimTrailingWhitespace" = true;

    "files.associations" = {
      "**/*.conf" = "ini";
      "**/conf*/{fuzzel,ghostty,mpv,hyprland}/*" = "ini";
      "**/conf*/{raffi}/*" = "yaml";
      "*.bash" = "shellscript";
      "*.css" = "tailwindcss";
      "*.gs" = "javascript";
      "*.init" = "shellscript";
      "*.lock" = "jsonc";
      "*.log" = "log";
      "*.nix" = "nix";
      "*.sh" = "shellscript";
      "*.typ" = "typst";
      ".bash*" = "shellscript";
      ".editorconfig" = "ini";
      ".env*" = "dotenv";
      ".envrc" = "shellscript";
      ".gitignore" = "ignore";
      ".ignore" = "ignore";
      ".shellcheckrc" = "shellscript";
      "Gemfile" = "ruby";
      "LICENSE" = "txt";
      "LICENSE-MIT" = "txt";
      "README" = "markdown";
      "editorconfig" = "ini";
    };

    "files.exclude" = {
      "**/.git" = false;
      "**/.DS_Store" = false;
      "**/.direnv" = false;
      "**/.vscode" = false;
      "**/target" = false;
    };

    "files.watcherExclude" = {
      "**/.local/**" = true;
      "**/.trunk/*actions/" = true;
      "**/.trunk/*logs/" = true;
    };
  };
}
