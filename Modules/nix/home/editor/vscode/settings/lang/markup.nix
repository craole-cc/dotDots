{
  lix,
  context,
  mkEnable,
  ...
}: let
  condition = true;
  lang = "markup";

  inherit (lix.lists.construction) concatLists;

  json = let
    defaultFormatter = "biomejs.biome";
  in {
    editor = {
      inherit defaultFormatter;
      # codeActionsOnSave.source.fixAll = "always";
    };
    extensions = [defaultFormatter];
    schemaDownload = {
      enable = true;
      trustedDomains = {
        "https://developer.microsoft.com/json-schemas/" = true;
        "https://json-schema.org/" = true;
        "https://json.schemastore.org/" = true;
        "https://raw.githubusercontent.com/devcontainers/spec/" = true;
        "https://raw.githubusercontent.com/microsoft/vscode/" = true;
        "https://schemastore.azurewebsites.net/" = true;
        "https://www.schemastore.org/" = true;
      };
      schemas = [
        {
          fileMatch = ["**/*.json" "**/*.jsonc"];
          schema.allowTrailingCommas = true;
        }
      ];
    };
  };

  toml = let
    defaultFormatter = "tombi-toml.tombi";
  in {
    editor = {
      inherit defaultFormatter;
      suggest.showKeywords = true;
      wordBasedSuggestions = "off";
    };
    extensions = [defaultFormatter];

    tombi = {
      #? Arguments to `tombi` command.
      # args = null;

      #? Environment variables to pass to `tombi` command.
      # env = null;

      #? Absolute path to tombi executable.
      # path = null;

      semanticTokens = {
        #? Send semantic tokens for ordinary comments. Set to `false` to let TextMate grammars and other extensions highlight comments. Tombi directive and region keywords are always highlighted. Requires restarting the language server.
        comments.enabled = true;

        #? Send semantic tokens for string values. Set to `false` to let TextMate grammars and other extensions highlight the inside of strings. Requires restarting the language server.
        strings.enabled = true;
      };
    };
  };

  ini = let
    defaultFormatter = "lkrms.inifmt";
  in {
    editor = {inherit defaultFormatter;};
    extensions = [defaultFormatter];
  };

  yaml = let
    defaultFormatter = "bluebrown.yamlfmt";
  in {
    editor = {inherit defaultFormatter;};
    redhat.telemetry.enabled = false;
    extensions = [defaultFormatter "redhat.vscode-yaml"];
  };

  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  extensions = concatLists (
    map (language: language.extensions)
    [ini json toml yaml]
  );

  getEd = lang: {inherit (lang) editor;};
  strip = lang: removeAttrs lang ["editor" "extensions"];
  settings =
    {
      "[ini]" = getEd ini;
      "[json]" = getEd json;
      "[jsonc]" = getEd json;
      "[toml]" = getEd toml;
      "[yaml]" = getEd yaml;
    }
    // (strip toml) // (strip yaml);
in {inherit enable extensions options settings;}
