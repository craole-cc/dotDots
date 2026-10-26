{cfg, ...}: let
  inherit (cfg.features.ui) dms catppuccin;
in {
  settings = {
    # json = {
    #   schemaDownload = {
    #     enable = true;
    #     trustedDomains = {
    #       "https://raw.githubusercontent.com/catppuccin/vscode/" = true;
    #     };
    #   };
    # };

    window = {
      #> Detect the system colour scheme and switch themes.
      autoDetectColorScheme = !dms;

      #> Auto-switch to a high-contrast theme to match the system.
      autoDetectHighContrast = !dms;
    };

    workbench = {
      #? Active colour theme.
      colorTheme =
        if dms
        then "Dynamic Base16 DankShell"
        else if catppuccin.enable
        then "Catppuccin Frappé"
        else "Dark 2026";

      #? Preferred dark theme (used when `autoDetectColorScheme` is on).
      preferredDarkColorTheme =
        if dms
        then "Dynamic Base16 DankShell (Dark)"
        else if catppuccin.enable
        then "Catppuccin Frappé"
        else "Dark 2026";

      #? Preferred light theme.
      preferredLightColorTheme =
        if dms
        then "Dynamic Base16 DankShell (Light)"
        else if catppuccin.enable
        then "Catppuccin Latte"
        else "Light 2026";

      #? Preferred HC dark theme.
      preferredHighContrastColorTheme = "Default High Contrast";

      #? Preferred HC light theme.
      preferredHighContrastLightColorTheme = "Default High Contrast Light";

      #? File icon theme.
      iconTheme = "material-icon-theme";

      #? Product icon theme.
      productIconTheme = "el-vsc-v1-icons";

      #> Overrides for the current colour theme.
      # colorCustomizations = {};
    };

    editor = {
      #> Semantic highlighting switch.
      #! overridden (default: "configuredByTheme")
      semanticHighlighting.enabled = true;

      #~@ Semantic token colour rules
      #> Colour and style for semantic token types.
      semanticTokenColorCustomizations = {
        rules = {
          "*.static".italic = true;
          interface.italic = true;
          keyword.italic = true;
          selfParameter.italic = true;
        };
      };

      #> Colour and style for TextMate scopes.
      tokenColorCustomizations = {
        "[*Light*]" = {
          textMateRules = [
            {
              scope = "ref.matchtext";
              settings = {foreground = "#000";};
            }
          ];
        };
        "[*Dark*]" = {
          textMateRules = [
            {
              scope = "ref.matchtext";
              settings = {foreground = "#fff";};
            }
          ];
        };
        textMateRules = [
          {
            scope = [
              "comment"
              "emphasis"
              "entity.name.tag.doctype"
              "entity.other.attribute-name"
              "keyword"
              "keyword.control"
              "keyword.operator.comparison"
              "keyword.operator.expression.delete"
              "keyword.operator.new"
              "keyword.operator.expression"
              "keyword.operator.cast"
              "keyword.operator.relational"
              "keyword.operator.sizeof"
              "italic"
              "markup.changed"
              "markup.deleted.diff"
              "markup.italic"
              "markup.quote"
              "meta.decorator punctuation.decorator"
              "meta.delimiter.period"
              "meta.diff.header.git"
              "meta.diff.header.from-file"
              "meta.diff.header.to-file"
              "markup.inserted.diff"
              "meta.tag.sgml.doctype"
              "meta.selector"
              "punctuation.accessor"
              "punctuation.definition.comment"
              "punctuation.definition.template-expression.begin"
              "punctuation.definition.template-expression.end"
              "punctuation.section.embedded"
              "quote"
              "storage"
              "storage.type"
              "storage.modifier"
              "text.html.basic entity.other.attribute-name.html"
              "text.html.basic entity.other.attribute-name"
              "variable.language"
              "variable.other.object.property"
            ];
            settings = {fontStyle = "italic";};
          }
        ];
      };

      #~@ Bracket Colorization & Guides
      #> Per-type bracket colour pools.
      #! overridden (default: false)
      bracketPairColorization.independentColorPoolPerBracketType = true;
    };
  };
}
