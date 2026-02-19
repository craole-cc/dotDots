{
  lib,
  user,
  ...
}: let
  inherit (lib.strings) hasInfix toLower;
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
in {
  _module.args.style = {
    inherit
      theme
      mode
      variant
      accent
      flavor
      catppuccin
      ;
  };
}
