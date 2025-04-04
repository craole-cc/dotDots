{ pkgs, ... }:
{
  imports = [ ];

  programs = {
    atuin.enable = true;
    bacon.enable = true;
    bat.enable = true;
    btop.enable = true;
    brave.enable = true;
    eza.enable = true;
    fastfetch.enable = true;
    fd.enable = true;
    freetube.enable = true;
    gh.enable = true;
    gh-dash.enable = true;
    ghostty.enable = true;
    git = {
      enable = true;
      userName = "Craole";
      userEmail = "32288735+Craole@users.noreply.github.com";
    };
    gitui.enable = true;
    helix.enable = true;
    jq.enable = true;
    # jujutsu.enable = true;
    mangohud.enable = true;
    mods.enable = true;
    rbw.enable = true;
    ripgrep.enable = true;
    ripgrep-all.enable = true;
    starship.enable = true;
    tealdeer.enable = true;
    topgrade.enable = true;
    vscode.enable = true;
    yazi.enable = true;
    yt-dlp.enable = true;
    zoxide.enable = true;
    zed-editor.enable = true;
  };
  home = {
    sessionVariables.READER = "bat";
    packages = with pkgs; [
      coreutils
      curl
      devenv
      diffutils
      dust
      eza
      fd
      findutils
      fzf
      gawk
      getent
      gh
      gitui
      gnused
      nerd-fonts.victor-mono
      nil
      nix-index
      nixd
      nixfmt-rfc-style
      onefetch
      # ripgrep
      rsync
      sd
      shellcheck
      shfmt
      tokei
      trashy
      treefmt
      undollar
      wget
      zig
    ];
  };
}
