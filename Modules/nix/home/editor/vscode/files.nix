{
  userSettings = {
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
      "*.nu" = "nushell";
      "*.rs" = "rust";
      "*.sh" = "shellscript";
      "*.typ" = "typst";
      ".bash*" = "shellscript";
      ".editorconfig" = "ini";
      ".env" = "env";
      ".env*" = "dotenv";
      ".envrc" = "shellscript";
      ".gitignore" = "ignore";
      ".ignore" = "ignore";
      ".shellcheckrc" = "shellscript";
      "flake.lock" = "json";
      "Gemfile" = "ruby";
      "LICENSE" = "txt";
      "LICENSE-MIT" = "txt";
      "README" = "markdown";
      "editorconfig" = "ini";
    };

    "files.exclude" = {
      "**/.git" = false;
      "**/.DS_Store" = false;
      "**/.admin" = false;
      "**/.bin" = false;
      "**/.direnv" = false;
      "**/.editorconfig" = false;
      "**/.env*" = false;
      "**/.gitattributes" = false;
      "**/.gitmodules" = false;
      "**/.github" = false;
      "**/.gitignore" = false;
      "**/.ignore" = false;
      "**/.helix" = false;
      "**/.hg" = false;
      "**/.jj" = false;
      "**/.justfile" = false;
      "**/.rust*" = false;
      "**/.shellcheckrc" = false;
      "**/.svn" = false;
      "**/.vscode" = false;
      "**/target" = false;
      "**/justfile" = false;
      "**/mise.toml" = false;
      "**/.mise.toml" = false;
    };

    "files.watcherExclude" = {
      "**/.local/**" = true;
      "**/.trunk/*actions/" = true;
      "**/.trunk/*logs/" = true;
      "**/.trunk/*notifications/" = true;
      "**/.trunk/*out/" = true;
      "**/.trunk/*plugins/" = true;
    };
  };
}
