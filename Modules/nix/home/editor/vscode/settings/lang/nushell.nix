{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "docker";
  condition = requires mod;
  options.${mod}.enable = mkEnable {inherit context condition;};
  enable = condition;
  extensions = [
    "thenuprojectcontributors.vscode-nushell-lang"
  ];
  settings = {};
in {inherit enable extensions options settings;}
