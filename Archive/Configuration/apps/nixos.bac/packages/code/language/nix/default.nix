{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nix-index
    manix
    rnix-lsp
    nixpkgs-fmt
    statix
    nil
    cachix
    alejandra
    vscode-extensions.kamadorueda.alejandra
    vscode-extensions.jnoortheen.nix-ide
    vscode-extensions.mkhl.direnv
  ];
}
