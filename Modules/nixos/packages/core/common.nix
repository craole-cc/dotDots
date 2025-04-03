{ pkgs, alpha, ... }:
{
  environment.systemPackages = with pkgs; [
    bat
    btop
    coreutils
    gnused
    curl
    lsd
    dust
    fastfetch
    fd
    findutils
    fzf
    gawk
    getent
    gh
    gitui
    gnused
    helix
    nil
    nix-index
    nixfmt-rfc-style
    ripgrep
    rsync
    trashy
    wget
  ];

  programs = {
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
    nix-ld.enable = true;
    starship.enable = true;
    vivid.enable = true;
    yazi.enable = true;
  };

  services = {
    atuin.enable = true;
    tailscale.enable = true;
  };

  users.users.${alpha}.packages = with pkgs; [
    # hello
    bat
    btop
    coreutils
    curl
    devenv
    diffutils
    dust
    eza
    fastfetch
    fd
    findutils
    fzf
    gawk
    getent
    gh
    gitui
    gnused
    gnused
    helix
    jq
    nerd-fonts.victor-mono
    nil
    nix-index
    nixd
    nixfmt-rfc-style
    onefetch
    ripgrep
    rsync
    sd
    shellcheck
    shfmt
    tldr
    tokei
    trashy
    treefmt
    undollar
    wget
    yazi
    zig
  ];
}
