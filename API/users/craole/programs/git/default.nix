{ policies, ... }:
{
  programs.git.enable = policies.dev;
  imports = [
    ./core.nix
    ./github.nix
    ./gitui.nix
    ./includes.nix
  ];
}
