{lib, ...}: let
  inherit (lib.modules) mkForce;
in {
  programs.vscode.profiles.default.userSettings = mkForce {
    # Editor Basics
    "editor.fontSize" = 18;
    "editor.fontFamily" = "'Maple Mono NF', 'VictorMono Nerd Font', 'Hack Nerd Font', 'monospace', monospace";
    "editor.lineHeight" = 2;
    "editor.tabSize" = 2;
    "editor.wordWrap" = "bounded";
    "editor.wordWrapColumn" = 120;

    # Editor Behavior
    "editor.accessibilitySupport" = "off";
    "editor.cursorBlinking" = "expand";
    "editor.cursorSmoothCaretAnimation" = "on";
    "editor.detectIndentation" = false;
    "editor.formatOnSave" = true;
    "editor.formatOnSaveMode" = "file";
    "editor.insertSpaces" = true;
    "editor.lineNumbers" = "relative";
    "editor.linkedEditing" = true;
    "editor.matchBrackets" = "never";
    "editor.mouseWheelZoom" = true;
    "editor.smoothScrolling" = true;

    # Editor Visual Features
    "editor.guides.bracketPairs" = "active";
    "editor.minimap.enabled" = true;
    "editor.minimap.size" = "fill";
    "editor.occurrencesHighlight" = "off";
    "editor.renderLineHighlight" = "gutter";
    "editor.selectionHighlight" = false;
    "editor.semanticHighlighting.enabled" = true;
    "editor.stickyScroll.enabled" = false;

    # IntelliSense
    "editor.inlineSuggest.suppressSuggestions" = true;
    "editor.inlayHints.enabled" = "offUnlessPressed";
    "editor.quickSuggestions" = {
      "strings" = "on";
    };
    "editor.suggestSelection" = "recentlyUsedByPrefix";

    # Semantic Tokens (Italics)
    "editor.semanticTokenColorCustomizations" = {
      "rules" = {
        "interface" = {
          "italic" = true;
        };
        "selfParameter" = {
          "italic" = true;
        };
        "keyword" = {
          "italic" = true;
        };
        "*.static" = {
          "italic" = true;
        };
      };
    };

    # Token Color Customizations (Extensive italics from your config)
    "editor.tokenColorCustomizations" = {
      "textMateRules" = [
        {
          "scope" = [
            "comment"
            "emphasis"
            "entity.name.method.js"
            "entity.name.class.js"
            "entity.name.tag.doctype"
            "entity.other.attribute-name"
            "keyword"
            "keyword.control"
            "keyword.operator.comparison"
            "keyword.control.flow.js"
            "keyword.control.flow.ts"
            "storage"
            "storage.type"
            "storage.modifier"
            "variable.language"
            "italic"
            "markup.italic"
            "meta.decorator punctuation.decorator"
          ];
          "settings" = {
            "fontStyle" = "italic";
          };
        }
      ];
    };

    # "editor.defaultFormatter" = "ibecker.treefmt-vscode";
    "explorer.compactFolders" = false;
  };
}
