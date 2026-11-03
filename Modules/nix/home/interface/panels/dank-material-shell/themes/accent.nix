{
  configHome,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.primitives) concat;
  inherit (pkgs) writeText;

  path = concat {
    root = configHome;
    stem = ["dms" "palette-accent.hex"];
  };
  name = "dms-palette-accent-template.toml";
  source = writeText name ''
    [templates.dms_palette_accent]
    input_path = '${./accent.txt}'
    output_path = '${path}'
  '';
in {
  accent = {
    inherit path;
    configFile."matugen/dms/configs/${name}" = {inherit source;};
  };
}
