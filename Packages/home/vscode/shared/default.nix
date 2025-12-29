{
  imports = [
    ./extensions.nix
    ./settings
    ./keybindings.nix
  ];

  profiles.default = {
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
  };
}
