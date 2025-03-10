{ pkgs, paths, ... }:
{
  env = [
    {
      name = "PATH";
      prefix = "${paths.scripts.store.flake}";
    }
    {
      name = "CACHE_DIR";
      eval = "$PRJ_ROOT/.cache";
    }
  ];

  commands = [
    {
      name = "rebuild";
      category = "System Management";
      command = ''sudo nixos-rebuild --flake $DOTS switch $@'';
      help = "Rebuild NixOS with the changes made to the flake";
    }
    {
      name = "clean";
      category = "System Management";
      command = ''nix-collect-garbage --delete-old'';
      help = "Remove old nixos and home-manager generations";
    }
    {
      name = "update";
      category = "System Management";
      command = ''update-repo.sh && update-flake.sh'';
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
    # {
    #   category = "Interactive Shell & Scripting";
    #   package = "just";
    # }
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
    # {
    #   category = "Environment Management";
    #   package = "rbw";
    # }
    {
      category = "Information Management";
      name = "rg";
      package = "ripgrep";
    }
    {
      category = "Interactive Shell & Scripting";
      name = "treefmt";
      package = "treefmt2";
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

  packages = with pkgs; [
    glib
    jq
    thefuck
    # fish-lsp
  ];
}
