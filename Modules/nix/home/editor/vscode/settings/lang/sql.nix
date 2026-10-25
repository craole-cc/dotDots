{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "sql";
  condition = requires [lang "sqlite"];
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  defaultFormatter = "adpyke.vscode-sql-formatter";
  extensions = [
    defaultFormatter
    "mtxr.sqltools"
    "mtxr.sqltools-driver-sqlite"
  ];

  settings = {
    "[${lang}]".editor = {inherit defaultFormatter;};
  };
in {inherit enable extensions options settings;}
