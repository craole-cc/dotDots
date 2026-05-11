{lib, ...}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.trivial) hasAny;

  editorGroups = {
    helix = ["helix" "hx"];
    neovim = ["neovim" "nvim"];
    rust-rover = [
      "idea"
      "jetbrains"
      "rust-rover"
      "rustrover"
    ];
    sublime = ["sublime-text" "sublime"];
    vscode = [
      "code"
      "cursor"
      "vscode-insiders"
      "vscode"
      "vscodium"
      "windsurf"
    ];
    zed = ["zed" "zeditor"];
  };

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
          target = [".shellcheckrc" "shellcheckrc"];
        };
        markdownlint = {
          source = mkSource "common" "markdownlint-cli2.yaml";
          target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
        };
        treefmt = {
          source = mkSource "common" "treefmt.toml";
          target = [".treefmt.toml" "treefmt.toml"];
        };
      }
      // optionalAttrs (hasAny editorGroups.helix editor.editors) {
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
      // optionalAttrs (hasAny editorGroups.neovim editor.editors) {
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
      // optionalAttrs (hasAny editorGroups.vscode editor.editors) {
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
      // optionalAttrs (hasAny editorGroups.zed editor.editors) {
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
      // optionalAttrs (hasAny editorGroups.rust-rover editor.editors) {
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
      // optionalAttrs (hasAny editorGroups.sublime editor.editors) {
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
in {inherit mkEditor;}
