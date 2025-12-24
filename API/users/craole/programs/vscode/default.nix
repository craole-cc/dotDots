{
  pkgs,
  ...
}: {
  imports = [./shared];
  config = {
    programs.vscode.enable = true;
    home.packages = [pkgs.vscode-fhs];
  };
}
