{ pkgs, osConfig, ... }:
{
  imports = [
    ./bat
    ./helix
  ];
  programs.home-manager.enable = true;
  home = {
    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "code-insiders";
    };
    stateVersion = osConfig.system.stateVersion;
    packages = with pkgs; [
      alejandra
      curl
      devenv
      fd
      fzf
      gitui
      jq
      nil
      # nix-index
      nixd
      nixfmt-rfc-style
      ripgrep
      sd
      shellcheck
      shfmt
      tldr
      tokei
      undollar
      cowsay
      wget
    ];
  };
  programs.atuin = {
    enable = true;
    daemon.enable = true;
    enableBashIntegration = true;
  };
}
