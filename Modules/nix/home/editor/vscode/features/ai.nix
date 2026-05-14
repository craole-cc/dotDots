{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}:
let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  copilot = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? AI inline completions
      "github.copilot"
      #? AI chat assistant
      "github.copilot-chat"
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
    };
  };

  codeium = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? alternative AI completions
      "codeium.codeium"
    ];
    userSettings = {
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
  };
  codex = mkVSCodeSubFeature {
    enabled = false;
    extensions = [ ];
    userSettings = { };
  };
  gemini = mkVSCodeSubFeature {
    enabled = false;
    extensions = [ ];
    userSettings = { };
  };
  continue = mkVSCodeSubFeature {
    enabled = false;
    extensions = [ ];
    userSettings = { };
  };
in
{
  name = "ai";
  description = "AI assistance extensions";
  default = true;
  feature =
    enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        copilot.extensions
        codeium.extensions
        codex.extensions
        gemini.extensions
        continue.extensions
      ];
      userSettings = mkMerge [
        (copilot.userSettings or { })
        (codeium.userSettings or { })
        (codex.userSettings or { })
        (gemini.userSettings or { })
        (continue.userSettings or { })
      ];
    };
}
