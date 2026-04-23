_: {
  userSettings = {
    # General
    "license.author" = "Craig 'Craole' Cole";
    "license.default" = "mit";
    "extensions.ignoreRecommendations" = true;
    "update.mode" = "manual";
    "security.workspace.trust.untrustedFiles" = "open";
    "diffEditor.codeLens" = true;
    "diffEditor.ignoreTrimWhitespace" = false;

    # Copilot
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

    # Codeium
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

    # LLDB
    "lldb.suppressUpdateNotifications" = true;
    "lldb.showDisassembly" = "auto";
    "lldb.dereferencePointers" = true;
    "lldb.consoleMode" = "commands";

    # Direnv
    "direnv.restart.automatic" = true;

    # Dotenv
    "dotenv.enableAutocloaking" = false;

    # Redhat
    "redhat.telemetry.enabled" = false;

    # Remote
    "remote.autoForwardPortsSource" = "hybrid";

    # Misc
    "atlascode.jira.enabled" = false;
    "settingsSync.ignoredExtensions" = [
      "jnoortheen.nix-ide"
      "mkhl.direnv"
      "ms-vscode-remote.remote-wsl"
    ];
  };
}
