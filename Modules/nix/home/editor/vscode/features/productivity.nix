{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lib.lists) flatten;
  inherit (lib.modules) mkMerge;
  inherit
    (lix.applications.editors)
    mkVSCodeFeature
    mkVSCodeSubFeature
    ;

  files = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Keyboard-driven file browser
      "bodil.file-browser"
      #? Sort workspace folders alphabetically
      "iciclesoft.workspacesort"
      #? Diff two folders side by side
      "moshfeu.compare-folders"
      #? Multi-workspace file search
      "joshmu.periscope"
    ];
  };

  text = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Text transformation utilities
      "dakara.transformer"
      #? Convert case (camel, snake, kebab…)
      "wmaurer.change-case"
      #? Sort selected lines
      "tyriar.sort-lines"
      #? Toggle editor settings via keybind
      "rebornix.toggle"
    ];
  };

  env = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? .env file support
      "dotenv.dotenv-vscode"
      #? .env syntax highlighting
      "irongeek.vscode-env"
      #? Respect .editorconfig files
      "editorconfig.editorconfig"
    ];
    userSettings = {
      "dotenv.enableAutocloaking" = false;
    };
  };

  license = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? License chooser and inserter
      "ultramarine.vscode-choosealicense"
    ];
    userSettings = {
      "license.author" = "Craig 'Craole' Cole";
      "license.default" = "mit";
    };
  };

  spelling = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Typos spell checker (fast, Rust-based)
      "tekumara.typos-vscode"
      #? CSpell spell checker
      "streetsidesoftware.code-spell-checker"
      #? Spell checking via system dictionary
      "ban.spellright"
      #? Highlight invisible/problematic chars
      "nhoizey.gremlins"
    ];
  };

  runners = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Reload window command
      "natqe.reload"
      #? Run code snippets in any language
      "formulahendry.code-runner"
      #? Test explorer sidebar UI
      "hbenl.vscode-test-explorer"
    ];
  };

  viewers = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? PlantUML diagram preview and export
      "jebbs.plantuml"
      #? Local dev server with live reload
      "ritwickdey.liveserver"
      #? PDF viewer inside VSCode
      "tomoki1207.pdf"
      #? SVG file preview
      "vitaliymaz.vscode-svg-previewer"
      #? Show import bundle size inline
      "wix.vscode-import-cost"
    ];
  };

  keybindings = mkVSCodeSubFeature {
    enabled = true;
    extensions = [
      #? Restore familiar Windows keybindings
      "smcpeak.default-keys-windows"
    ];
  };
in {
  name = "productivity";
  description = "Workflow, file management and utility extensions";
  default = true;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        files.extensions
        text.extensions
        env.extensions
        license.extensions
        spelling.extensions
        runners.extensions
        viewers.extensions
        keybindings.extensions
      ];
      userSettings = mkMerge [
        (files.userSettings      or {})
        (text.userSettings       or {})
        (env.userSettings        or {})
        (license.userSettings    or {})
        (spelling.userSettings   or {})
        (runners.userSettings    or {})
        (viewers.userSettings    or {})
        (keybindings.userSettings or {})
      ];
    };
}
