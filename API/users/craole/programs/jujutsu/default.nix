{ policies, ... }:
{
  programs.git.enable = policies.dev;
  imports = [
    ./core.nix
    ./jjui.nix
  ];
}
