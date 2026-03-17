{lix, ...}: let
  inherit (lix.types.options) mkTrue;
in {
  option = mkTrue "AI assistance extensions";

  extensions = [
    "github.copilot"
    "github.copilot-chat"
    "codeium.codeium"
  ];

  settings = {
    "github.copilot.enable" = {
      "*" = false;
      "nix" = true;
      "shellscript" = true;
    };
    "github.copilot.nextEditSuggestions.enabled" = true;
    "codeium.disableSupercomplete" = true;
    "codeium.enableSearch" = true;
    "codeium.enableConfig" = {
      "*" = true;
      "nix" = true;
      "typst" = true;
      "cypher" = true;
    };
  };
}
