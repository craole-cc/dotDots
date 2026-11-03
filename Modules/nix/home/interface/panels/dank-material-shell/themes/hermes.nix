{
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.filesystem.primitives) concat;
  inherit (pkgs) writeText;
in {
  hermes = let
    tag = "hermes-matugen";
    template = ./hermes.yaml;
    outputPath = concat {
      root = config.home.homeDirectory;
      stem = [".hermes" "skins" "dms-wallpaper.yaml"];
    };
    source = writeText "dotdots-${tag}.toml" ''
      [templates.dotdots_hermes]
      input_path = '${template}'
      output_path = '${outputPath}'
    '';
  in {
    skinPath = outputPath;
    configFile."matugen/dms/configs/${tag}.toml".source = source;
  };
}
