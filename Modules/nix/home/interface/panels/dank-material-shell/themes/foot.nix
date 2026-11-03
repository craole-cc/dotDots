{
  lix,
  pkgs,
  user,
  configHome,
  ...
}: let
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.strings.construction) concatStringsSep;
  inherit (lix.styles.palettes) mkFootPalette;
  inherit (pkgs) writeText;
  inherit (user.theme) modes;
in {
  foot = let
    path = concat {
      root = configHome;
      stem = ["foot" "dank-colors.ini"];
    };
    tag = "foot-matugen-theme";
    file = "${tag}.toml";
    target = concat {
      root = configHome;
      stem = ["matugen" "dms" "configs" file];
    };
    source = writeText file ''
      [templates.${tag}]
      input_path = '${./foot.ini}'
      output_path = '${path}'
    '';
    fallback = writeText "foot-fallback-theme.ini" (
      concatStringsSep "\n" (map mkFootPalette (with modes; [dark light]))
    );
  in {
    configFile."${target}" = {inherit source;};
    matugenTemplateEnabled = true;
    inherit fallback path;
  };
}
