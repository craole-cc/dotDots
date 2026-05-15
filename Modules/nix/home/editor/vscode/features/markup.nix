{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  markdown = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Markdown linter
      "davidanson.vscode-markdownlint"
      #? Markdown shortcuts, TOC, preview
      "yzhang.markdown-all-in-one"
      #? Export markdown to PDF
      "yzane.markdown-pdf"
      #? CSV column colorizer
      # "mechatroner.rainbow-csv"
      #? Mermaid diagram preview in markdown
      # "bierner.markdown-mermaid"
      #? GitHub-flavored markdown preview
      "bierner.github-markdown-preview"
    ];
    userSettings = {
      "[markdown]"."editor.defaultFormatter" = "DavidAnson.vscode-markdownlint";
      "markdown.updateLinksOnFileMove.enabled" = "always";
      "markdown.validate.enabled" = true;
      "markdown.preview.typographer" = true;
      "markdown-pdf.breaks" = true;
      "markdown-pdf.displayHeaderFooter" = false;
      "markdown-pdf.format" = "Letter";
      # "markdown.marp.enableHtml" = true;
      # "markdown.marp.pdf.noteAnnotations" = true;
      # "markdown.marp.pdf.outlines" = "both";
      # "markdown.marp.exportType" = "html";
      # "markdown.marp.strictPathResolutionDuringExport" = true;
    };
  };

  dataFormats = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
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
    ];
    userSettings = {
      "[toml]"."editor.defaultFormatter" = "tamasfe.even-better-toml";
      "[yaml]"."editor.defaultFormatter" = "redhat.vscode-yaml";
      "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
      "redhat.telemetry.enabled" = false;
    };
  };

  typst = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Typst LSP and preview
      "myriad-dreamin.tinymist"
    ];
    userSettings = {
      "[typst]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";
      "[typst-code]"."editor.defaultFormatter" = "myriad-dreamin.tinymist";
    };
  };

  tooling = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Justfile syntax highlighting
      "nefrob.vscode-just-syntax"
      #? mise version manager integration
      "hverlin.mise-vscode"
      #? log file syntax highlighting
      "emilast.logfilehighlighter"
    ];
  };
in {
  name = "markup";
  description = "Markdown, TOML, YAML, config format extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        markdown.extensions
        dataFormats.extensions
        typst.extensions
        tooling.extensions
      ];
      userSettings = mkMerge [
        (markdown.userSettings or {})
        (dataFormats.userSettings or {})
        (typst.userSettings or {})
        (tooling.userSettings or {})
      ];
    };
}
