{dmsEnabled, lix, ...}: let
  inherit (lix.attrsets.construction) optionalAttrs;
in {
  # Keep behavioral configuration in Home Manager, but delegate terminal
  # colors to DMS when DMS owns the desktop shell. DMS regenerates the
  # `dankcolors` Ghostty theme from its active Material/Matugen palette.
  settings = optionalAttrs dmsEnabled {
    theme = "dankcolors";
  };
}
