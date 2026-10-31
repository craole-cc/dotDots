{
  config,
  entryAfter,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (pkgs) writeText;
  directory = concat {
    root = config.xdg.configHome;
    stem = ["yazi"];
  };
in {
  yazi = {
    configFile."matugen/dms/configs/yazi-matugen-template.toml".source = writeText "yazi-matugen-template.toml" ''
      [templates.dms_yazi]
      input_path = '${./yazi.toml}'
      output_path = '${directory}/theme.toml'
    '';
    activation = entryAfter ["writeBoundary"] ''
      mkdir -p ${escapeShellArg directory}
    '';
  };
}
