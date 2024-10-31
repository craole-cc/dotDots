{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nushell
    nu_scripts
    vscode-extensions.thenuprojectcontributors.vscode-nushell-lang
  ];
}
