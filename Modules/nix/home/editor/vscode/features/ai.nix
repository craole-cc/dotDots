{lix, ...}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  enabled:
    mkVSCodeFeature {
      inherit enabled;
      extensions = [
        #? AI inline completions
        "github.copilot"
        #? AI chat assistant
        "github.copilot-chat"
        #? alternative AI completions
        "codeium.codeium"
      ];
      userSettings = {
        "github.copilot.enable" = {
          "*" = false;
          "plaintext" = false;
          "markdown" = false;
          "scminput" = false;
          "nix" = true;
          "shellscript" = true;
          "rust" = false;
          "powershell" = false;
        };
        "github.copilot.chat.codesearch.enabled" = true;
        "github.copilot.chat.editor.temporalContext.enabled" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "codeium.disableSupercomplete" = true;
        "codeium.enableSearch" = true;
        "codeium.enableConfig" = {
          "*" = true;
          "nix" = true;
          "jsonc" = true;
          "just" = true;
          "markdown" = true;
          "typst" = true;
          "cypher" = true;
        };
      };
    }
