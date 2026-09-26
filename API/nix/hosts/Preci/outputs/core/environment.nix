{host, lix, pkgs, ...}: {
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor =
      let
        flavor = host.interface.themes.dark.flavor or "frappe";
      in
        if flavor == "Catppuccin Frappé" then "frappe"
        else if flavor == "Catppuccin Latte" then "latte"
        else lix.toLower flavor;
    accent = host.interface.themes.dark.accent or "mauve";
  };

  console.keyMap = host.principals.primary.interface.keyboard.layout;

  documentation.nixos.enable = false;

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

  i18n.defaultLocale = host.localization.defaultLocale;

  system.stateVersion = host.stateVersion;

  time.timeZone = host.localization.timeZone;
}
