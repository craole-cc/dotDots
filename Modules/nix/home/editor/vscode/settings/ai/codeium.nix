{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "codeium";
  condition = requires mod;
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = ["codeium.codeium"];
  settings.${mod} = {
    disableSupercomplete = true;
    enableSearch = true;
    enableConfig = {
      "*" = true;
      "nix" = true;
      "jsonc" = true;
      "just" = true;
      "markdown" = true;
      "typst" = true;
      "cypher" = true;
    };
  };
in {inherit enable extensions options settings;}
