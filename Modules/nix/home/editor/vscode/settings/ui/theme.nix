{
  cfg,
  lix,
  ...
}: let
  inherit (lix.attrsets.construction) optionalAttrs;
in {
  extensions = ["Catppuccin.catppuccin-vsc"];
  settings = {
    json = {
      schemaDownload = {
        enable = true;
        trustedDomains = {
          "https://raw.githubusercontent.com/catppuccin/vscode/catppuccin-vsc-v3.19.0/packages/catppuccin-vsc/schemas/colorOverrides.schema.json" = true;
          "https://raw.githubusercontent.com/catppuccin/vscode/catppuccin-vsc-v3.19.0/packages/catppuccin-vsc/schemas/customUIColors.schema.json" = true;
        };
      };
    };

    window = {
      #> Detect the system colour scheme and switch themes.
      #! overridden (default: false)
      autoDetectColorScheme = false;

      #> Auto-switch to a high-contrast theme when the OS is in HC mode.
      #! overridden (default: true)
      autoDetectHighContrast = false;
    };

    workbench =
      {
        #? Active colour theme.
        #! overridden (default: "Dark 2026")
        colorTheme = "Catppuccin Frappé";

        #? Preferred dark theme (used when `autoDetectColorScheme` is on).
        preferredDarkColorTheme = "Catppuccin Frappé";

        #? Preferred light theme.
        preferredLightColorTheme = "Catppuccin Latte";

        #? Preferred HC dark theme.
        preferredHighContrastColorTheme = "Default High Contrast";

        #? Preferred HC light theme.
        preferredHighContrastLightColorTheme = "Default High Contrast Light";

        #? File icon theme.
        #! overridden (default: "vs-seti")
        iconTheme = "material-icon-theme";

        #? Product icon theme.
        #! overridden (default: "Default")
        productIconTheme = "el-vsc-v1-icons";

        #> Overrides for the current colour theme.
        colorCustomizations = {};
      }
      // (
        optionalAttrs cfg.features.ui.dms {
          window.autoDetectColorScheme = false;
          workbench.colorTheme = "Dynamic Base16 DankShell";
        }
      );

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

      guides = {
        #> Vertical bracket guides.
        #?  - true | active | false
        #! overridden (default: false)
        bracketPairs = "active";
        #> Horizontal bracket guides.
        #?  - true | active | false
        bracketPairsHorizontal = "active";
        #> Highlight active bracket pair.
        highlightActiveBracketPair = true;
        #> Highlight active indent guide.
        #?  - true | always | false
        highlightActiveIndentation = true;
        #> Show indent guides.
        indentation = true;
      };
      #> Highlight matching brackets.
      #?  - always | near | never
      #! overridden (default: "always")
      matchBrackets = "always";
    };
  };
}
