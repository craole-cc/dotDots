{_, ...}: let
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) findFirstOrNull head;
  inherit (_.lists.predicates) any;
  inherit (_.schema.fonts) mkFonts;
  inherit (_.strings.construction) optionalString;
  inherit (_.strings.predicates) hasInfix;
  inherit (_.strings.transformation) toLower;

  mkStyle = {
    host,
    user ? {},
  }: let
    legacyTheme = user.interface.style.theme or (host.interface.style.theme or {});
    mode = toLower (
      user.theme.modes.default.palette.variant
      or host.theme.modes.default.palette.variant
      or legacyTheme.mode
      or "dark"
    );
    palette = user.theme.modes.${mode}.palette or (host.theme.modes.${mode}.palette or {});
    variant = toLower (palette.name or (legacyTheme.${mode} or "Catppuccin Latte"));
    accentValue = palette.accent or (legacyTheme.accent or "rosewater");
    accentName = findFirstOrNull
      (name: palette.colors.${name} == accentValue)
      (attrNames (palette.colors or {}));
    accent = toLower (if accentName == null then accentValue else accentName);
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
    catppuccin = any (polarity:
      hasInfix "catppuccin" (toLower (
        user.theme.modes.${polarity}.palette.name
        or (host.theme.modes.${polarity}.palette.name or "")
      ))) ["dark" "light"];

    fonts = mapAttrs (_: entries:
      optionalString (entries != []) (head entries).family)
    (mkFonts {inherit host user;}).categories;

    icons = {
      dark =
        user.theme.modes.dark.icon
        or user.style.icons.dark
        or host.theme.modes.dark.icon
        or host.style.icons.dark
        or "candy-icons";
      light =
        user.theme.modes.light.icon
        or user.style.icons.light
        or host.theme.modes.light.icon
        or host.style.icons.light
        or "candy-icons";
    };
    cursors = {
      dark =
        user.theme.modes.dark.cursor
        or user.style.cursors.dark
        or host.theme.modes.dark.cursor
        or host.style.cursors.dark
        or "material-cursors";
      light =
        user.theme.modes.light.cursor
        or user.style.cursors.light
        or host.theme.modes.light.cursor
        or host.style.cursors.light
        or "catppuccin-cursors";
    };
    opacity = {
      editor = {
        light =
          user.theme.modes.light.opacity.editor
          or user.style.opacity.editor.light
          or host.theme.modes.light.opacity.editor
          or host.style.opacity.editor.light
          or 1.0;
        dark =
          user.theme.modes.dark.opacity.editor
          or user.style.opacity.editor.dark
          or host.theme.modes.dark.opacity.editor
          or host.style.opacity.editor.dark
          or 1.0;
      };
      terminal = {
        light =
          user.theme.modes.light.opacity.terminal
          or user.style.opacity.terminal.light
          or host.theme.modes.light.opacity.terminal
          or host.style.opacity.terminal.light
          or 1.0;
        dark =
          user.theme.modes.dark.opacity.terminal
          or user.style.opacity.terminal.dark
          or host.theme.modes.dark.opacity.terminal
          or host.style.opacity.terminal.dark
          or 1.0;
      };
    };
  in {
    inherit
      fonts
      mode
      variant
      accent
      flavor
      catppuccin
      icons
      cursors
      opacity
      ;
  };

  exports = {inherit mkStyle;};
in
  exports
  // {
    __rootAliases = {
      mkUserStyle = mkStyle;
    };
  }
