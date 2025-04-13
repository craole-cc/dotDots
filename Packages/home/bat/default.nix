{ pkgs, ... }:
let
  catppuccin = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
  };
  theme = "Catppuccin-latte";
in
# inherit (config.dots.users.craole) name theme;
# inherit (userArgs.theme) colors;
# inherit (colors) mode;
# inherit (colors.${mode}) scheme;
# theme = scheme.${app};
{
  # options.${dom}.${mod} = {
  #   enable = mkEnableOption "${mod}";
  # };
  # config.${dom}.${mod} = mkIf cfg.enable {
  programs.bat = {
    # enable = true;
    config = {
      inherit theme;
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
}
