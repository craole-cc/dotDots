{ pkgs, osConfig, ... }:
{
  imports = [
    ./bat
    ./helix
  ];
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
      # helix
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
  programs = {
    atuin = {
      enable = true;
      daemon.enable = true;
      enableBashIntegration = true;
    };
    # bat.enable = true;
    direnv = {
      enable = true;
      silent = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      prompt.enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
    home-manager.enable = true;
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };
}
