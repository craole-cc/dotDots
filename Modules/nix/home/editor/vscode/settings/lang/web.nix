{
  # lix,
  context,
  mkEnable,
  ...
}: let
  lang = "web";
  condition = true;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  # inherit (lix.attrsets.construction) optionalAttrs;
  # inherit (lix.attrsets.aggregation) mergeSafe;
  # inherit (lix.lists.predicates) isIn;

  defaultFormatter = "biomejs.biome";

  extensions = [
    defaultFormatter
    "bradlc.vscode-tailwindcss"
    "phu1237.vs-browser"
    "phoenisx.cssvar"
  ];

  editor = {inherit defaultFormatter;};
  settings = {
    "[javascript]" = {inherit editor;};
    "[typescript]" = {inherit editor;};
    "[html]" = {inherit editor;};
    "[css]" = {inherit editor;};
    "[scss]" = {inherit editor;};
    "[json]" = {inherit editor;};
    "[jsonc]" = {inherit editor;};

    tailwindCSS = {
      includeLanguages.plaintext = "html";
    };
    cssvar = {
      files = [
        "./node_modules/open-props/open-props.min.css"
        "assets/styles/variables.css"
        "style.css"
      ];
      extensions = ["css" "postcss" "jsx" "tsx"];
      ignore = [];
    };

    vs-browser = {
      favourites.list = {
        "http://127.0.0.1:3000" = "http://127.0.0.1:3000";
        "http://localhost" = "http://localhost";
      };
      link = {
        enabled = true;
        openWith = "ask";
      };
      localProxyServer = {
        cookieDomainRewrite = true;
        enabled = true;
        forceLocation = true;
      };
      reload = {
        autoReloadDurationEnabled = false;
        autoReloadDurationTime = 15000;
        onSave = false;
      };
      url = "http://127.0.0.1:3000";
    };

    # json.schemaDownload = {
    #   enable = true;
    #   trustedDomains = let
    #     trustFormatter = name: link:
    #       optionalAttrs (isIn name defaultFormatter) {${link} = true;};
    #   in
    #     mergeSafe [
    #       (trustFormatter "biome" "https://biomejs.dev")
    #       (trustFormatter "dprint" "https://dprint.dev")
    #     ];
    # };

    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = [
          "entity.name.method.js"
          "entity.name.class.js"
          "keyword.control.flow.js"
          "keyword.control.flow.ts"
          "keyword.control.flow.tsx"
          "keyword.control.loop.js"
          "keyword.control.loop.ts"
          "keyword.control.import.js"
          "keyword.control.import.ts"
          "keyword.control.import.tsx"
          "keyword.control.from.js"
          "keyword.control.from.ts"
          "keyword.control.from.tsx"
          "meta.class meta.method.declaration meta.var.expr storage.type.js"
          "source.js constant.other.object.key.js string.unquoted.label.js"
          "storage.type.property.js"
          "storage.type.property.ts"
          "storage.type.property.tsx"
          "tag.decorator.js entity.name.tag.js"
          "tag.decorator.js"
        ];
        settings.fontStyle = "italic";
      }
    ];
  };
in {inherit enable extensions options settings;}
