{ pkgs, paths, ... }:
#TODO: Update to match the toml
{
  name = "Media";
  env = [
    {
      name = "PATH";
      prefix =
        let
          inherit (paths.parts) bin;
          shellscript = "$PRJ_ROOT" + bin.shellscript;
          dots = "$PRJ_ROOT" + bin.dots;
          flake = "$PRJ_ROOT" + bin.flake;
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
      category = "File/Environment Management";
      package = "bat";
    }
    {
      category = "File/Environment Management";
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
      category = "File/Environment Management";
      package = "eza";
    }
    {
      category = "File/Environment Management";
      package = "fd";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "fish";
    }
    {
      category = "File/Environment Management";
      package = "fastfetch";
    }
    {
      category = "File/Environment Management";
      package = "fzf";
    }
    {
      category = "Project Management";
      package = "gitui";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "just";
    }
    # {
    #   category = "File/Environment Management";
    #   package = "lsd";
    # }
    # {
    #   category = "Interactive Shell & Scripting";
    #   name = "nu";
    #   package = "nushell";
    # }
    {
      category = "Interactive Shell & Scripting";
      name = "pwsh";
      package = "powershell";
    }
    {
      category = "File/Environment Management";
      package = "rbw";
    }
    {
      category = "File/Environment Management";
      name = "rg";
      package = "ripgrep";
    }
    {
      category = "Project Management";
      name = "treefmt";
      package = "treefmt2";
    }
    {
      category = "File/Environment Management";
      package = "yazi";
    }
    {
      category = "Interactive Shell & Scripting";
      name = "zeditor";
      package = "zed-editor-fhs";
      command = ''
        if [ "$#" -gt 0 ]; then
          zeditor "$@"
        else
          zeditor "$PRJ_ROOT"
        fi
      '';
      help = '' High-performance Integrated Development Environment (IDE)'';
    }
    {
      category = "File/Environment Management";
      package = "zoxide";
    }
    {
      category = "Interactive Shell & Scripting";
      package = "zsh";
    }
  ];

  packages = with pkgs; [
    atuin
    bash-language-server
    biome
    jq
    thefuck
    nixd
    gitoxide
    fish-lsp
    # zed-editor-fhs
  ];
}
