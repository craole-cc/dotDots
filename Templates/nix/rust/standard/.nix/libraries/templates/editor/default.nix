{lib, ...}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.lists) any concatLists elem filter toList unique;
  inherit (lib.strings) isString toLower;

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

  knownEditors = concatLists (attrValues editorGroups);

  hasAny = needles: haystack: any (x: elem x haystack) needles;

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

  normalizeEditors = editor:
    if editor == null || editor == false
    then {
      base = false;
      editors = [];
    }
    else if editor == true
    then {
      base = true;
      editors = [];
    }
    else if isString editor && toLower editor == "all"
    then {
      base = true;
      editors = knownEditors;
    }
    else {
      base = true;
      editors = unique (
        filter (e: elem e knownEditors) (map toLower (toList editor))
      );
    };

  mkEditor = editor: let
    normalized = normalizeEditors editor;
  in
    optionalAttrs (editor != null) (
      optionalAttrs normalized.base {
        editorconfig = {
          base = {
            source = mkSource "common" "editorconfig";
            target = ".editorconfig";
          };
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
      // optionalAttrs (
        hasAny
        editorGroups.helix
        normalized.editors
      ) {
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
      // optionalAttrs (
        hasAny
        editorGroups.neovim
        normalized.editors
      ) {
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
      // optionalAttrs (
        hasAny
        editorGroups.vscode
        normalized.editors
      ) {
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
      // optionalAttrs (
        hasAny
        editorGroups.zed
        normalized.editors
      ) {
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
      // optionalAttrs (
        hasAny
        editorGroups.rust-rover
        normalized.editors
      ) {
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
      // optionalAttrs (
        hasAny
        editorGroups.sublime
        normalized.editors
      ) {
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
