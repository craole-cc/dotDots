{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Markdown linter
        "davidanson.vscode-markdownlint"
        #? Markdown shortcuts, TOC, preview
        "yzhang.markdown-all-in-one"
        #? Export markdown to PDF
        "yzane.markdown-pdf"
        #? CSV column colorizer
        "mechatroner.rainbow-csv"
        #? Mermaid diagram preview in markdown
        "bierner.markdown-mermaid"
        #? GitHub-flavored markdown preview
        "bierner.github-markdown-preview"
        #? YAML LSP and validation
        "redhat.vscode-yaml"
        #? YAML formatter
        "bluebrown.yamlfmt"
        #? TOML LSP and formatter
        "tamasfe.even-better-toml"
        #? INI/properties formatter
        "lkrms.inifmt"
        #? KDL document language support
        "kdl-org.kdl"
        #? Typst LSP and preview
        "myriad-dreamin.tinymist"
        #? Justfile syntax highlighting
        "nefrob.vscode-just-syntax"
        #? mise version manager integration
        "hverlin.mise-vscode"
        #? log file syntax highlighting
        "emilast.logfilehighlighter"
      ];
      userSettings = {
        "[markdown]"."editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
        "markdown.updateLinksOnFileMove.enabled" = "always";
        "markdown.validate.enabled" = true;
        "markdown.preview.typographer" = true;
        "markdown-pdf.breaks" = true;
        "markdown-pdf.displayHeaderFooter" = false;
        "markdown-pdf.format" = "Letter";
        "markdown.marp.enableHtml" = true;
        "markdown.marp.pdf.noteAnnotations" = true;
        "markdown.marp.pdf.outlines" = "both";
        "markdown.marp.exportType" = "html";
        "markdown.marp.strictPathResolutionDuringExport" = true;
        "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
        "[yaml]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[typst]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";
        "[typst-code]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";
        "redhat.telemetry.enabled" = false;
      };
    }
