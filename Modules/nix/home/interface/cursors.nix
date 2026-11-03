{
  lix,
  pkgs,
  style,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkOption;
  inherit (lix.styles.cursors) mkOne;
  inherit (lix.types.primitives) str;

  resolveCursor = polarity: requested: let
    size =
      if polarity == "dark"
      then 32
      else 24;
  in
    if isIn requested ["material-cursors" "material"]
    then {
      name = "material_${polarity}_cursors";
      package = pkgs.material-cursors;
      inherit size;
    }
    else let
      resolved = mkOne ({
          inherit pkgs polarity size;
          cursor = requested;
        }
        // {
          accent =
            if isIn requested ["catppuccin-cursors" "catppuccin"]
            # TODO: this should not be hardcoded, it must come from themes.<mode>.
            then "mauve"
            else null;
        });
    in {inherit (resolved) name package size;};
in {
  options.themes.cursors = {
    dark = mkOption {
      type = str;
      default = style.cursors.dark;
      description = "Cursor theme requested for dark mode";
      apply = resolveCursor "dark";
    };

    light = mkOption {
      type = str;
      default = style.cursors.light;
      description = "Cursor theme requested for light mode";
      apply = resolveCursor "light";
    };
  };
}
