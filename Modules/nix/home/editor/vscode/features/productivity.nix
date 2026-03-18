{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in {
  name = "productivity";
  description = "Workflow, file management and utility extensions";
  default = false;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Keyboard-driven file browser
        "bodil.file-browser"
        #? Sort workspace folders alphabetically
        "iciclesoft.workspacesort"
        #? Diff two folders side by side
        "moshfeu.compare-folders"
        #? Multi-workspace file search
        "joshmu.periscope"
        #? Text transformation utilities
        "dakara.transformer"
        #? Convert case (camel, snake, kebab…)
        "wmaurer.change-case"
        #? Sort selected lines
        "tyriar.sort-lines"
        #? Toggle editor settings via keybind
        "rebornix.toggle"
        #? .env file support
        "dotenv.dotenv-vscode"
        #? .env syntax highlighting
        "irongeek.vscode-env"
        #? Respect .editorconfig files
        "editorconfig.editorconfig"
        #? Typos spell checker (fast, Rust-based)
        "tekumara.typos-vscode"
        #? CSpell spell checker
        "streetsidesoftware.code-spell-checker"
        #? Spell checking via system dictionary
        "ban.spellright"
        #? Highlight invisible/problematic chars
        "nhoizey.gremlins"
        #? Reload window command
        "natqe.reload"
        #? Run code snippets in any language
        "formulahendry.code-runner"
        #? Test explorer sidebar UI
        "hbenl.vscode-test-explorer"
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
        #? Restore familiar Windows keybindings
        "smcpeak.default-keys-windows"
      ];
      userSettings = {
        "dotenv.enableAutocloaking" = false;
      };
    };
}
