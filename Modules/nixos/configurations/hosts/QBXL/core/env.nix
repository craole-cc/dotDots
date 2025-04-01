{ pkgs, ... }:
let
  alpha = "craole";
  dots= "/home/${alpha}/.dots";
in
{
  environment = {
    variables = {
      EDITOR = "hx";
      VISUAL = "code";
      DOTS =dots;
    };
    systemPackages = with pkgs; [
      (writeScriptBin ".dots" ''
        exec "${dots}/Bin/shellscript/project/.dots" "$@"
      '')
      alejandra
      curl
      devenv
      fd
      fzf
      gitui
      helix
      jq
      nil
      nixd
      nix-index
      nixfmt-rfc-style
      ripgrep
      sd
      shfmt
      shellcheck
      tldr
      tokei
      undollar
      wget
    ];
  };
  programs = {
    bat.enable = true;
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
    lazygit.enable = true;
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };
}
