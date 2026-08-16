{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;

  mkSource = group: name: ./. + "/${group}/${name}";

  mkEntry = {
    group,
    name,
    prefix ? ".",
  }: {
    source = mkSource group name;
    target =
      if prefix == ""
      then name
      else "${prefix}${group}/${name}";
  };

  mkEditor = editor:
    optionalAttrs editor.enable (
      optionalAttrs editor.base {
        editorconfig = {
          source = mkSource "common" "editorconfig";
          target = ".editorconfig";
        };
        shellcheck = {
          source = mkSource "common" "shellcheckrc";
          target = [
            ".shellcheckrc"
            "shellcheckrc"
          ];
        };
        markdownlint = {
          source = mkSource "common" "markdownlint-cli2.yaml";
          target = [
            ".markdownlint-cli2.yaml"
            "markdownlint-cli2.yaml"
          ];
        };
        treefmt = {
          source = mkSource "common" "treefmt.toml";
          target = [
            ".treefmt.toml"
            "treefmt.toml"
          ];
        };
      }
      // optionalAttrs editor.helix {
        helix = {
          config = mkEntry {
            group = "helix";
            name = "config.toml";
          };
          languages = mkEntry {
            group = "helix";
            name = "languages.toml";
          };
        };
      }
      // optionalAttrs editor.neovim {
        neovim = {
          neoconf = {
            source = mkSource "neovim" "neoconf.json";
            target = ".neoconf.json";
          };
          config = {
            source = mkSource "neovim" "nvim.lua";
            target = ".nvim.lua";
          };
        };
      }
      // optionalAttrs editor.vscode {
        vscode = {
          settings = mkEntry {
            group = "vscode";
            name = "settings.json";
          };
          extensions = mkEntry {
            group = "vscode";
            name = "extensions.json";
          };
          tasks = mkEntry {
            group = "vscode";
            name = "tasks.json";
          };
          launch = mkEntry {
            group = "vscode";
            name = "launch.json";
          };
        };
      }
      // optionalAttrs editor.zed {
        zed = {
          settings = mkEntry {
            group = "zed";
            name = "settings.json";
          };
          tasks = mkEntry {
            group = "zed";
            name = "tasks.json";
          };
        };
      }
      // optionalAttrs editor.rust-rover {
        rust-rover = {
          rust = mkEntry {
            group = "idea";
            name = "rust.xml";
          };
          misc = mkEntry {
            group = "idea";
            name = "misc.xml";
          };
          cargo-run = mkEntry {
            group = "idea";
            name = "runConfigurations/cargo.xml";
          };
          cargo-test = mkEntry {
            group = "idea";
            name = "runConfigurations/tests.xml";
          };
        };
      }
      // optionalAttrs editor.sublime {
        sublime-text = {
          project = mkEntry {
            group = "sublime-text";
            name = "project.sublime-project";
            prefix = "";
          };
          settings = mkEntry {
            group = "sublime-text";
            name = "Preferences.sublime-settings";
            prefix = "";
          };
        };
      }
    );
in {
  inherit mkEditor;
}
