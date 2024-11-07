{
  lib,
  pkgs,
  config,
  wsl_user,
  wsl_conf,
  wsl_vr3n,
  ...
}:
{
  home = {
    username = lib.mkDefault wsl_user;
    homeDirectory = lib.mkDefault "/home/${wsl_user}";
    stateVersion = lib.mkDefault wsl_vr3n;
    sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
  };
  programs = {
    home-manager.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        NixOS-WSL = "cd ${wsl_conf} && sh init";
        fmt_wsl_conf = "alejandra format ${wsl_conf} --quiet --exclude ${wsl_conf}/archive";
      };
    };
    starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[›](bold green)";
          error_symbol = "[›](bold red)";
        };

        git_status = {
          deleted = "✗";
          modified = "✶";
          staged = "✓";
          stashed = "≡";
        };

        nix_shell = {
          symbol = " ";
        };
      };
    };
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "Catppuccin-mocha";
      };
      themes = {
        Catppuccin-mocha = builtins.readFile (
          pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/bat/main/Catppuccin-mocha.tmTheme";
            hash = "sha256-qMQNJGZImmjrqzy7IiEkY5IhvPAMZpq0W6skLLsng/w=";
          }
        );
      };
    };
  };
}
