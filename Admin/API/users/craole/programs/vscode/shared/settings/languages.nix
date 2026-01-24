{
  programs.vscode.profiles.default.userSettings = {
    # Nix
    "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
    "nix.serverPath" = "nixd";
    "nix.enableLanguageServer" = true;
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = ["nixfmt"];
        };
      };
    };

    # PowerShell
    "[powershell]" = {
      "editor.defaultFormatter" = "ms-vscode.powershell";
      "editor.renderControlCharacters" = true;
      "editor.tabCompletion" = "on";
      "files.encoding" = "utf8bom";
    };
    "powershell.codeFormatting.autoCorrectAliases" = true;
    "powershell.codeFormatting.useCorrectCasing" = true;
    "powershell.integratedConsole.showOnStartup" = false;
    "powershell.integratedConsole.suppressStartupBanner" = true;

    # Rust
    "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
    "rust-analyzer.check.command" = "clippy";

    # Shell
    "[shellscript]"."editor.defaultFormatter" = "mkhl.shfmt";
    "[bats]"."editor.defaultFormatter" = "mkhl.shfmt";

    # Web
    "[javascript]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[typescript]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[html]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[json]"."editor.defaultFormatter" = "vscode.json-language-features";

    # Markup
    "[markdown]"."editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
    "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
    "[yaml]" = {};

    # TypeScript
    "typescript.inlayHints.parameterNames.enabled" = "all";

    # Tailwind
    "tailwindCSS.includeLanguages" = {
      "plaintext" = "html";
    };

    # Markdown
    "markdown.updateLinksOnFileMove.enabled" = "always";
    "markdown.validate.enabled" = true;
  };
}
