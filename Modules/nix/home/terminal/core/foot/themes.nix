{
  dmsEnabled ? false,
  dmsColorsPath ? "~/.config/foot/dotdots-dms-colors.ini",
}: let
  alpha = 0.95;
in
  {
    # Cursor behavior remains owned by dotDots regardless of palette source.
    cursor = {
      style = "beam";
      blink = "yes";
      blink-rate = 500;
      beam-thickness = 1.5;
    };
  }
  // (
    if dmsEnabled
    then {
      # DMS owns palette values. The runtime sync helper materializes both
      # [colors-dark] and [colors-light] from DMS's dual-scheme color state so
      # Foot can switch modes server-wide without rewriting this Nix config.
      main.include = dmsColorsPath;
    }
    else {
      # Non-DMS fallback remains deterministic and fully Nix-owned.
      colors-dark = {
        inherit alpha;
        background = "303446";
        foreground = "c6d0f5";
      };

      colors-light = {
        inherit alpha;
        background = "eff1f5";
        foreground = "4c4f69";
      };
    }
  )
