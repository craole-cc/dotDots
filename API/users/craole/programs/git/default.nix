{
  lib,
  user,
  ...
}: let
  app = "git";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  enable = elem app allowed;
in {
  programs = {
    git = {inherit enable;};
    gitui = {inherit enable;};
    gh = {inherit enable;};
    gh-dash = {inherit enable;};
  };

  imports = [
    ./core.nix
    ./github.nix
    ./gitui.nix
  ];
}
