{config, top, ...}: {
  config = {
    programs.bat = {
      enable = config.${top}.inputs.applications.utilities.bat.enable;
      config = {
        pager = "less -F";
        # theme = "dark";
      };
      #   themes = let
      #     catppuccin = pkgs.fetchFromGitHub {
      #       owner = "catppuccin";
      #       repo = "bat";
      #       rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
      #       hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
      #     };
      #   in {
      #     dark = {
      #       src = catppuccin;
      #       file = "Catppuccin-frappe.tmTheme";
      #     };
      #     light = {
      #       src = catppuccin;
      #       file = "Catppuccin-latte.tmTheme";
      #     };
      #   };
    };

    ${top}.output = {
      programs.bat = {
        enable = config.${top}.inputs.applications.utilities.bat.enable;
        config = {
          pager = "less -F";
          # theme = "dark";
        };
      };
    };
  };
}
