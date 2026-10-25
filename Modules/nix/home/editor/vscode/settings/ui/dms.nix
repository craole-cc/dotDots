{
  context,
  mkEnable,
  ...
}: let
  name = "dms";
  inherit (context.wantsDmsShell) condition;
in {
  inherit name;
  description = "DankMaterialShell integration";
  enable = condition;
  options.${name}.enable = mkEnable {inherit context condition;};
  extensions = ["DankLinux.dms-theme"];
  settings = {};
}
