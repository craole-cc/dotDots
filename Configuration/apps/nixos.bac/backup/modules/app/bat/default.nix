{ config, lib, ... }:
let
  app = "bat";
in
# inherit (userArgs.theme) colors;
# inherit (colors) mode;
# inherit (colors.${mode}) scheme;
# theme = scheme.${app};
{
  options.dots.${app} = {
    enable = mkEnableOption "${app} config";
  };

  programs.bat = {
    enable = true;
    config = {
      # inherit theme;
      pager = "less -FR";
    };
    # themes = let
    #   src = pkgs.fetchFromGitHub {
    #     owner = "catppuccin";
    #     repo = "bat";
    #     rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
    #     hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
    #   };
    # in {
    #   Catppuccin-mocha = {
    #     inherit src;
    #     file = "Catppuccin-mocha.tmTheme";
    #   };
    #   Catppuccin-latte = {
    #     inherit src;
    #     file = "Catppuccin-latte.tmTheme";
    #   };
    # };
  };
}
