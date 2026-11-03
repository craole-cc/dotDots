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
in {
  helix = let
    theme = rec {
      directory = concat {
        root = config.xdg.configHome;
        stem = ["helix" "themes"];
      };
      path = concat {
        root = directory;
        stem = ["base16_transparent.toml"];
      };
      activation = entryAfter ["writeBoundary"] ''
        mkdir -p ${escapeShellArg directory}
      '';
    };

    template = rec {
      name = "helix-matugen-template.toml";
      path = ./helix.toml;
      source = writeText name ''
        [templates.dms_helix]
        input_path = '${path}'
        output_path = '${theme.path}'
      '';
      target = concat {
        root = "matugen";
        stem = ["dms" "configs" name];
      };
    };
  in {
    configFile."${template.target}" = {inherit (template) source;};
    inherit (theme) activation;
  };
}
