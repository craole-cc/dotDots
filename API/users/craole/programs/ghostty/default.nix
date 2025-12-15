{policies, ...}: let
  enable = policies.devGui;
in {
  programs.ghostty = {
    inherit enable;
    systemd = {inherit enable;};
  };

  imports = [
    ./settings.nix
    ./themes.nix
  ];
}
