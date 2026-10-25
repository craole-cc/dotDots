{
  context,
  mkEnable,
  ...
}: let
  inherit (context) wantsDmsShell;
  mod = "dms";
  inherit (wantsDmsShell) condition;
in {
  name = mod;
  description = "DankMaterialShell integration";
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};
  extensions = [];
  settings = {};
}
