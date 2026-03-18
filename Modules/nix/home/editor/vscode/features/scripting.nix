{
  inputs,
  lib,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature mkVSCodeSubFeature;
  inherit (lib.modules) mkMerge;
  inherit (lib.lists) flatten;

  python = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Python LSP and tooling
      "ms-python.python"
      #? Python debugger
      "ms-python.debugpy"
      #? fast Python type checker
      "ms-python.vscode-pylance"
      #? Ruff linter/formatter
      "charliermarsh.ruff"
    ];
    userSettings = {
      "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";
      "python.analysis.typeCheckingMode" = "basic";
    };
  };

  nushell = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? Nushell language support
      "thenuprojectcontributors.vscode-nushell-lang"
    ];
  };

  powershell = mkVSCodeSubFeature {
    enabled = false;
    extensions = [
      #? PowerShell LSP and debugger
      "ms-vscode.powershell"
    ];
    userSettings = {
      "[powershell]" = {
        "editor.defaultFormatter" = "ms-vscode.powershell";
        "editor.renderControlCharacters" = true;
        "editor.tabCompletion" = "on";
        "files.encoding" = "utf8bom";
      };
      "powershell.codeFormatting.autoCorrectAliases" = true;
      "powershell.codeFormatting.useCorrectCasing" = true;
      "powershell.integratedConsole.showOnStartup" = false;
      "powershell.integratedConsole.suppressStartupBanner" = true;
    };
  };
in {
  name = "scripting";
  description = "Python, Nushell, PowerShell extensions";
  default = false;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = flatten [
        python.extensions
        nushell.extensions
        powershell.extensions
      ];
      userSettings = mkMerge [
        (python.userSettings     or {})
        (nushell.userSettings    or {})
        (powershell.userSettings or {})
      ];
    };
}
