{ pkgs, paths, ... }:
{
  name = "dotDots";
  env = [
    {
      name = "PATH";
      prefix =
        let
          shellscript = "$PRJ_ROOT" + "/Bin/shellscript";
          dots = "$PRJ_ROOT" + "/Scripts";
          flake = "$PRJ_ROOT" + "/Modules/nixos/scripts";
        in
        ''
          ${shellscript}:${dots}:${flake}
        '';
    }
    {
      name = "XDG_CACHE_DIR";
      eval = "$PRJ_ROOT/.cache";
    }
    {
      name = "XDG_CONFIG_HOME";
      eval = "$PRJ_ROOT/.config";
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
      name = "repo";
      category = "System Management";
      command = ''sync-repo.sh'';
      help = "Sync git repository";
    }
    {
      name = "flake";
      category = "System Management";
      command = ''sync-repo.sh && update.sh'';
      help = "Update flake inputs and sync git repository";
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
      category = "Interactive Shell & Scripting";
      package = "devenv";
    }
    {
      category = "Interactive Shell & Scripting";
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
      category = "Environment Management";
      package = "gitui";
    }
    {
      category = "Environment Management";
      package = "hub";
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
      category = "Interactive Shell & Scripting";
      name = "treefmt";
      package = "treefmt2";
    }
    {
      category = "Environment Management";
      package = "yazi";
    }
    {
      category = "Interactive Shell & Scripting";
      name = "zeditor";
      command = ''
        if [ "$#" -gt 0 ]; then
          zeditor "$@"
        else
          zeditor "$PRJ_ROOT"
        fi
      '';
      package = "zed-editor";
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
    bash-language-server
    glib
    jq
    thefuck
    nixd
    gitoxide
    zed-editor
    # fish-lsp
  ];
}
