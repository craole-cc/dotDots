{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      editor = import ./editor.nix;
      keys = import ./keybindings.nix;
    };
    languages = import ./languages.nix;
  };
  packages = with pkgs; [
    bash-language-server
    zls
    shfmt
    shellcheck
  ];
}
