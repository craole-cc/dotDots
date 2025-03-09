{
  pkgs ? import <nixpkgs> { },
  ...
}:
{
  # motd = ''
  #   Welcome to the development environment!
  # '';

  packages = with pkgs; [
    bat
    btop
    direnv
    eza
    fastfetch
    fd
    fzf
    glib
    jq
    lsd
    ripgrep
    thefuck
    lesspipe
    yazi
    zoxide
    bashInteractive
    fish
    nushell
    powershell
    rbw
    zsh
    just
  ];

  commands = [
    {
      name = "rebuild";
      category = "System Management";
      command = "sudo nixos-rebuild --flake $DOTS switch $@";
      help = "Rebuild NixOS with the changes made to the flake";
    }
    {
      name = "clean";
      category = "System Management";
      command = "nix-collect-garbage --delete-old";
      help = "Remove old nixos and home-manager generations";
    }
    {
      name = "update";
      category = "System Management";
      command = ''
        #!/bin/sh

        #@ Ensure strict mode and exit on error
        set -euo pipefail

        #@ Pull repo changes, capturing output
        PULL_OUTPUT=$(git pull --quiet --autostash 2>&1)
        PULL_IGNORE="Already up to date."
        case "$PULL_OUTPUT" in *"$PULL_IGNORE"*) ;;
          *) printf "%s\n" "$PULL_OUTPUT" ;;
        esac

        #@ Update flake inputs
        nix flake update

        #@ Sync repo and push changes
        git add --all :/
        if git status --porcelain | grep -q .; then
          msg="General updates"
          [ $# -gt 0 ] && msg="$*"
          git commit --message "$msg" || true
          git push
        fi
      '';
      help = "Update flake inputs, sync repo, and push changes";
    }

    {
      category = "Interactive Shell & Scripting";
      name = "bash";
      package = "bashInteractive";
    }
    {
      category = "Information Management";
      package = "bat";
    }
    {
      category = "Information Management";
      package = "btop";
    }
    {
      category = "Environment Management";
      package = "direnv";
    }
    {
      category = "Environment Management";
      package = "eza";
    }
    {
      category = "Environment Management";
      package = "fd";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "fish";
    }
    {
      category = "Information Management";
      package = "fastfetch";
    }
    {
      category = "Environment Management";
      package = "fzf";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "just";
    }
    {
      category = "Environment Management";
      package = "lsd";
    }
    {
      category = "Interactive Shell & Scripting";
      name = "nu";
      package = "nushell";
    }
    {
      category = "Interactive Shell & Scripting";
      name = "pwsh";
      package = "powershell";
    }
    {
      category = "Environment Management";
      package = "rbw";
    }
    {
      category = "Information Management";
      name = "rg";
      package = "ripgrep";
    }
    {
      category = "Environment Management";
      package = "yazi";
    }
    {
      category = "Environment Management";
      package = "zoxide";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "zsh";
    }
  ];
}
