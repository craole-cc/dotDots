{
  userSettings = {
    #~@ Nix
    "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nixd";
    "nix.serverSettings"."nixd" = {
      "formatting"."command" = ["alejandra"];
      "diagnostic"."suppress" = ["sema-primop-overridden"];
    };

    #~@ Rust
    "[rust]"."editor.defaultFormatter" = "rust-lang.rust-analyzer";
    "rust-analyzer.check.command" = "clippy";
    "rust-analyzer.cargo.features" = "all";

    #~@ Shell
    "[shellscript]"."editor.defaultFormatter" = "mkhl.shfmt";
    "[bats]"."editor.defaultFormatter" = "mkhl.shfmt";
    "[dotenv]"."editor.defaultFormatter" = "mkhl.shfmt";

    #~@ Web
    "[javascript]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[typescript]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[html]"."editor.defaultFormatter" = "denoland.vscode-deno";
    "[json]"."editor.defaultFormatter" = "vscode.json-language-features";
    "[jsonc]"."editor.defaultFormatter" = "vscode.json-language-features";
    "[scss]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
    "typescript.inlayHints.parameterNames.enabled" = "all";
    "tailwindCSS.includeLanguages"."plaintext" = "html";

    #~@ Markup
    "[markdown]"."editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
    "markdown.updateLinksOnFileMove.enabled" = "always";
    "markdown.validate.enabled" = true;
    "markdown.preview.typographer" = true;
    "markdown.preview.fontFamily" = "Maple Mono NF, sans-serif, -apple-system, BlinkMacSystemFont";
    "markdown-pdf.breaks" = true;
    "markdown-pdf.displayHeaderFooter" = false;
    "markdown-pdf.format" = "Letter";

    #~@ Typst
    "[typst]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";
    "[typst-code]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";

    #~@ TOML
    "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";

    #~@ PowerShell
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

    #~@ GitHub Actions
    "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";

    #~@ CSS vars
    "cssvar.files" = [
      "./node_modules/open-props/open-props.min.css"
      "assets/styles/variables.css"
      "style.css"
    ];
    "cssvar.extensions" = ["css" "postcss" "jsx" "tsx"];
    "cssvar.ignore" = [];

    #~@ Marp
    "markdown.marp.enableHtml" = true;
    "markdown.marp.pdf.noteAnnotations" = true;
    "markdown.marp.pdf.outlines" = "both";
    "markdown.marp.exportType" = "html";
    "markdown.marp.strictPathResolutionDuringExport" = true;
  };
}
