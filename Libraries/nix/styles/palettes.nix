{_, ...}: let
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.transformation) imap0;
  inherit (_.strings.construction) concatStringsSep;
  inherit (_.strings.transformation) stripHash;

  # Format each color with its zero-based index (as a string), then join the lines.
  mkLines = format: colors:
    concatStringsSep "\n" (
      imap0
      (index: color: format (toString index) color)
      colors
    );

  # All 16 ANSI colors in order.
  ansi = terminal: (terminal.regular or []) ++ (terminal.bright or []);

  mkTerminalPalette = input: let
    palette = input.palette or input;
    resolve = mapAttrs (_: color: palette.colors.${color} or color);
    regular = resolve palette.ansi.regular;
    bright = regular // resolve palette.ansi.bright;
    ordered = slots:
      map (slot: slots.${slot})
      ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"];
  in {
    inherit (palette) name variant foreground background;
    selectionBackground = palette.surface;
    cursor = palette.accent;
    regular = ordered regular;
    bright = ordered bright;
  };

  mkFootPalette = colors: let
    palette = mkTerminalPalette colors;
  in ''
    # ${palette.name}
    [colors-${palette.variant}]
    foreground=${stripHash palette.foreground}
    background=${stripHash palette.background}
    selection-foreground=${stripHash palette.foreground}
    selection-background=${stripHash palette.selectionBackground}
    cursor=${stripHash palette.background} ${stripHash palette.cursor}

    ${concatStringsSep "\n" (
      map
      (
        kind:
          mkLines
          (index: color: "${kind}${index}=${stripHash color}")
          palette.${kind}
      )
      ["regular" "bright"]
    )}
  '';

  mkKittyPalette = colors: let
    palette = mkTerminalPalette colors;
  in ''
    # ${palette.name}
    foreground ${palette.foreground}
    background ${palette.background}
    selection_foreground ${palette.foreground}
    selection_background ${palette.selectionBackground}
    cursor ${palette.cursor}

    ${
      mkLines
      (index: color: "color${index} ${color}")
      (ansi palette)
    }
  '';

  mkGhosttyPalette = colors: let
    palette = mkTerminalPalette colors;
  in ''
    # ${palette.name}
    foreground = ${palette.foreground}
    background = ${palette.background}
    selection-foreground = ${palette.foreground}
    selection-background = ${palette.selectionBackground}
    cursor-color = ${palette.cursor}
    ${
      mkLines
      (index: color: "palette = ${index}=${color}")
      (ansi palette)
    }
  '';
in {
  inherit
    ansi
    mkFootPalette
    mkGhosttyPalette
    mkKittyPalette
    mkLines
    mkTerminalPalette
    ;
}
