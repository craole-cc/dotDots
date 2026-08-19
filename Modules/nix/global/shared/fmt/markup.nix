{
  lix,
  pkgs,
  flake,
  binaries,
  ...
}: let
  inherit (flake) path;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) fromJSON;

  config = fromJSON (readFile "${path}/dprint.json");
in {
  programs = {
    dprint = {
      enable = true;

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

      settings =
        (removeAttrs config [
          "$schema"
          "includes"
          "excludes"
          "plugins"
        ])
        // {
          markdown = removeAttrs config.markdown [
            "headingKind"
            "listIndentKind"
          ];

          plugins = pkgs.dprint-plugins.getPluginList (plugins:
            with plugins; [
              dprint-plugin-json
              dprint-plugin-markdown
              g-plane-pretty_yaml
              g-plane-malva
            ]);
        };
    };

    typstyle.enable = true;
  };

  settings.formatter = {
    dprint = {
      priority = 1;
      options = ["--allow-no-files"];
    };
    harper = {
      command = binaries.harper;
      options = ["check" "--format" "short"];
      includes = ["Documentation/**/*.md" "Documentation/**/*.typ"];
      priority = 1;
    };
    tombi = {
      command = binaries.tombi;
      options = ["format" "--offline"];
      includes = ["*.toml"];
      priority = 1;
    };
  };
}
