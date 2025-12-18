{pkgs, ...}: {
  imports = [];
  home.packages = with pkgs; [powershell];
}
