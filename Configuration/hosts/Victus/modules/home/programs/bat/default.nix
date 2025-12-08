{ policies, ... }:
{
  programs.bat.enable = policies.dev;
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
