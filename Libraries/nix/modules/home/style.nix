{lib, ...}: let
  inherit (lib.strings) hasInfix toLower;

  mkStyle = {
    host,
    user,
  }: let
    theme = user.interface.style.theme or {};
    mode = toLower (theme.mode or "dark");
    variant = toLower (theme.${mode} or "Catppuccin Latte");
    accent = toLower (theme.accent or "rosewater");
    flavor =
      if hasInfix "frappe" variant || hasInfix "frappé" variant
      then "frappe"
      else if hasInfix "latte" variant
      then "latte"
      else if hasInfix "mocha" variant
      then "mocha"
      else if hasInfix "macchiato" variant
      then "macchiato"
      else if mode == "dark"
      then "frappe"
      else "latte";
    catppuccin = hasInfix "catppuccin" variant;
    fonts =
      user.interface.style.fonts or host.interface.style.fonts or {
        emoji = "Noto Color Emoji";
        monospace = "Maple Mono NF";
        sans = "Monaspace Radon Frozen";
        serif = "Noto Serif";
        material = "Material Symbols Sharp";
        clock = "Rubik";
      };
  in {inherit fonts mode variant accent flavor catppuccin;};

  exports = {inherit mkStyle;};
in
  exports // {_rootAliases = {mkUserStyle = mkStyle;};}
