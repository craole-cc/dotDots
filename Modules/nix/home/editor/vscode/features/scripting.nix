{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Python LSP and tooling
        "ms-python.python"
        #? Python debugger
        "ms-python.debugpy"
        #? fast Python type checker
        "ms-python.vscode-pylance"
        #? Ruff linter/formatter
        "charliermarsh.ruff"
        #? Nushell language support
        "thenuprojectcontributors.vscode-nushell-lang"
        #? PowerShell LSP and debugger
        "ms-vscode.powershell"
      ];
      userSettings = {
        "[python]"."editor.defaultFormatter" = "charliermarsh.ruff";
        "python.analysis.typeCheckingMode" = "basic";
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
    }
