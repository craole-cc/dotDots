{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "python";
  condition = requires [lang "python3"];
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};
  defaultFormatter = "charliermarsh.ruff";

  extensions = [
    defaultFormatter
    "fill-labs.dependi"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-python.vscode-python-envs"
    "formulahendry.code-runner"
  ];

  settings = {
    "[${lang}]".editor = {inherit defaultFormatter;};
    ${lang} = {
      analysis.typeCheckingMode = "basic";
    };

    editor.tokenColorCustomizations.textMateRules = [
      {
        scope = ["keyword.operator.logical.${lang}"];
        settings.fontStyle = "italic";
      }
    ];
  };
in {inherit enable extensions options settings;}
