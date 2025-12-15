{
  pkgs,
  lib,
  policies,
  ...
}:
{
  imports = [ ./shared ];
  config = lib.mkIf policies.devGui {
    programs.vscode.enable = true;
    home.packages = [ pkgs.vscode-fhs ];
  };
}
