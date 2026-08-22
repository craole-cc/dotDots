{
  flake,
  commands,
  ...
}: let
  inherit (flake) path;
in {
  programs = {
    dprint = {
      enable = true;
      settings = {
        lineWidth = 120;
        indentWidth = 2;
        useTabs = false;
        newLineKind = "lf";
        json = {
          indentWidth = 2;
          lineWidth = 120;
          trailingCommas = "never";
        };
        markdown = {
          lineWidth = 120;
          newLineKind = "lf";
          textWrap = "maintain";
          emphasisKind = "underscores";
          strongKind = "asterisks";
          unorderedListKind = "dashes";
          headingKind = "atx";
          listIndentKind = "commonMark";
        };
        yaml = {
          printWidth = 120;
          indentWidth = 2;
          quotes = "preferDouble";
          trailingComma = true;
          formatComments = false;
          indentBlockSequenceInMap = true;
          braceSpacing = true;
          bracketSpacing = false;
          dashSpacing = "oneSpace";
          preferSingleLine = false;
          trimTrailingWhitespaces = true;
          trimTrailingZero = false;
          proseWrap = "preserve";
        };
        malva = {
          printWidth = 120;
          useTabs = false;
          quotes = "preferDouble";
          singleLineTopLevelDeclarations = false;
        };
        includes = [
          "**/*.{json,jsonc}"
          "**/*.md"
          "**/*.{yml,yaml}"
          "**/*.{css,scss,sass,less}"
        ];
        excludes = [
          "**/node_modules"
          "**/*-lock.json"
          "**/flake.lock"
          "**/result"
          "**/.direnv"
          "**/target"
          "**/dist"
          "**/.git"
          "Configuration/**"
          "Documentation/**"
          "Environment/**"
          "Assets/**"
          "Review/**"
          "Scripts/**"
          "Tasks/**"
          "Templates/**"
          "Modules/global/**"
          "Modules/nixos/configurations/hosts/QBX/**"
          "Modules/nixos/scripts/**"
        ];
        plugins = [
          "https://plugins.dprint.dev/json-0.23.0.wasm"
          "https://plugins.dprint.dev/markdown-0.22.1.wasm"
          "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm"
          "https://plugins.dprint.dev/g-plane/malva-v0.16.0.wasm"
        ];
      };
      includes = [
        "*.json"
        "*.jsonc"
        "*.md"
        "*.yaml"
        "*.yml"
        "*.css"
        "*.scss"
        "*.sass"
        "*.less"
      ];
    };
    typstyle.enable = true;
  };

  settings.formatter = {
    dprint = {
      priority = 1;
      options = [
        "--allow-no-files"
        "--config"
        "${path}/dprint.json"
      ];
    };
    harper = {
      command = commands.harper;
      options = [
        "check"
        "--format"
        "short"
      ];
      includes = [
        "Documentation/**/*.md"
        "Documentation/**/*.typ"
      ];
      priority = 1;
    };
    tombi = {
      command = commands.tombi;
      options = [
        "format"
        "--offline"
      ];
      includes = ["*.toml"];
      priority = 1;
    };
  };
}
