{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "docker";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "ms-azuretools.vscode-docker";
  extensions = [defaultFormatter];
  settings."[dockerfile]".editor = {inherit defaultFormatter;};
in {inherit enable extensions options settings;}
