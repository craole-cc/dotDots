{ policies, ... }:
{
  programs.helix.enable = true;
  # programs.helix.enable = policies.dev;
  imports = [
    ./editor.nix
    ./keybindings.nix
    ./languages.nix
    ./themes.nix
  ];
}
