{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "craole";
  app = "bat";

  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
  };
in
# inherit (config.dots.users.craole) name theme;
# inherit (userArgs.theme) colors;
# inherit (colors) mode;
# inherit (colors.${mode}) scheme;
# theme = scheme.${app};
{
  config.dots.users.craole = {
    programs.bat = {
      enable = true;
      config = {
        # inherit theme;
        theme = "Catppuccin-latte";
        pager = "less -FR";
      };

      themes = {
        Catppuccin-mocha = {
          src = catppuccin;
          file = "Catppuccin-mocha.tmTheme";
        };
        Catppuccin-latte = {
          src = catppuccin;
          file = "Catppuccin-latte.tmTheme";
        };
      };
    };

    variables.READER = "bat";
  };
}
