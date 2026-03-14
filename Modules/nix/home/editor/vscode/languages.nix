{
  userSettings = {
    #~@ Nix
    "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
    nix = {
      enableLanguageServer = true;
      serverPath = "nixd";
      serverSettings = {
        nixd = {
          formatting.command = ["alejandra"];
          diagnostic.suppress = ["sema-primop-overridden"];
        };
      };
    };

    #~@ PowerShell
    "[powershell]" = {
      editor = {
        defaultFormatter = "ms-vscode.powershell";
        renderControlCharacters = true;
        tabCompletion = "on";
      };
      files.encoding = "utf8bom";
    };
    powershell = {
      codeFormatting = {
        autoCorrectAliases = true;
        useCorrectCasing = true;
      };
      integratedConsole = {
        showOnStartup = false;
        suppressStartupBanner = true;
      };
    };

    #~@ Rust
    "[rust]".editor.defaultFormatter = "rust-lang.rust-analyzer";
    rust-analyzer.check.command = "clippy";

    #~@ Shellscript
    "[shellscript]".editor.defaultFormatter = "mkhl.shfmt";
    "[bats]".editor.defaultFormatter = "mkhl.shfmt";

    #~@ Web
    "[javascript]".editor.defaultFormatter = "denoland.vscode-deno";
    "[typescript]".editor.defaultFormatter = "denoland.vscode-deno";
    typescript.inlayHints.parameterNames.enabled = "all";
    "[html]".editor.defaultFormatter = "denoland.vscode-deno";
    "[json]".editor.defaultFormatter = "vscode.json-language-features";
    tailwindCSS.includeLanguages = {
      plaintext = "html";
    };

    #~@ Markup
    "[markdown]".editor.defaultFormatter = "DavidAnson.vscode-markdownlint";
    markdown = {
      updateLinksOnFileMove.enabled = "always";
      validate.enabled = true;
    };
    "[toml]".editor.defaultFormatter = "tamasfe.even-better-toml";
    "[yaml]" = {};
  };
}
