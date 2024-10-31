{
  config,
  lib,
  pkgs,
  ...
}:
let
  # cfg = config.dots.sources.home-manager;
  name = "stylix";
in
with builtins;
with lib;
with types;
# with cfg;
{
  options.dots.sources.external.stylix = {
    enable = mkEnableOption "{{name}} Source";
    source = mkOption {
      description = "The path to the {{stylix}} source";
      default =
        let
          repo = pkgs.fetchFromGitHub {
            owner = "danth";
            repo = "stylix";
            rev = "master";
            sha256 = "W9Y/+K4L7JcF5xcXO4MVGQk/0DgzHrp/IjlHyLeYExY=";
          };
        in
        "${repo}/nixos";
      type = path;
    };
  };

  # stylix.image = pkgs.fetchurl {
  #   url = "https://www.pixelstalk.net/wp-content/uploads/2016/05/Epic-Anime-Awesome-Wallpapers.jpg";
  #   sha256 = "enQo3wqhgf0FEPHj2coOCvo7DuZv+x5rL/WIo4qPI50=";
  # };
}
