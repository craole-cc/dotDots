{
  imports = [
    ./extensions.nix
    ./settings
    ./keybindings.nix
  ];

  programs.vscode.profiles.default = {
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
  };
}
