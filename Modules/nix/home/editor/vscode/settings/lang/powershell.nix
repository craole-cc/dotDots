{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "powershell";
  condition = requires [lang "pwsh"];
  options.${lang}.enable = mkEnable {inherit context condition;};
  enable = condition;

  #? PowerShell LSP and debugger
  formatter = "ms-vscode.powershell";

  extensions = [formatter];

  settings = {
    "[${lang}]" = {
      editor = {
        defaultFormatter = formatter;
        renderControlCharacters = true;
        renderWhitespace = "all";
        tabCompletion = "on";
      };
      files = {
        autoGuessEncoding = true;
        encoding = "utf8bom";
        trimTrailingWhitespace = true;
      };
    };
    ${lang} = {
      codeFormatting = {
        autoCorrectAliases = true;
        trimWhitespaceAroundPipe = true;
        useConstantStrings = true;
        useCorrectCasing = true;
        whitespaceBetweenParameters = true;
      };
      integratedConsole = {
        focusConsoleOnExecute = false;
        forceClearScrollbackBuffer = true;
        showOnStartup = false;
        suppressStartupBanner = true;
      };
    };
  };
in {inherit enable extensions options settings;}
