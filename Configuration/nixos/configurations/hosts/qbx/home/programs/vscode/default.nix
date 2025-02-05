{pkgs, ...}: {
  imports = [];
  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
  };
}
