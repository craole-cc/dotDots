{
  host,
  lix,
  pkgs,
  ...
}: let
  inherit (host) stateVersion localisation;
  inherit (lix.strings) toLower;
in {
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = let
      flavor = host.interface.themes.dark.flavor or "frappe";
    in
      if flavor == "Catppuccin Frappé"
      then "frappe"
      else if flavor == "Catppuccin Latte"
      then "latte"
      else toLower flavor;
    accent = host.interface.themes.dark.accent or "mauve";
  };

  console = {
    keyMap = host.principals.primary.interface.keyboard.layout;
  };

  documentation = {
    nixos.enable = false;
  };

  fonts = {
    packages = with pkgs; [
      rubik
      noto-fonts-color-emoji
      material-symbols
      maple-mono.NF-unhinted
      monaspace
      noto-fonts
    ];

    fontconfig.defaultFonts = {
      monospace = ["Maple Mono NF"];
      sansSerif = ["Monaspace Radon Frozen"];
      serif = ["Noto Serif"];
      emoji = ["Noto Color Emoji"];
    };
  };

  i18n = {inherit (localisation) defaultLocale;};
  system = {inherit stateVersion;};
  time = {inherit (localisation) timeZone;};
}
