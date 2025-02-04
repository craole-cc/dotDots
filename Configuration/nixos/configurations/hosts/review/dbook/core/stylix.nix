{
  pkgs,
  config,
  ...
}:
let
  inherit (config.DOTS.pictures) wallpapers;
  stylix = pkgs.fetchFromGitHub {
    owner = "danth";
    repo = "stylix";
    rev = "master";
    sha256 = "W9Y/+K4L7JcF5xcXO4MVGQk/0DgzHrp/IjlHyLeYExY=";
  };
in
{
  imports = [
    # (import stylix).nixosModules.stylix
    "${stylix}/nixosModules/stylix"
  ];

  stylix = {
    enable = true;
    image = "/home/craole/Pictures/Wallpapers/light.jpg";
    # image = wallpapers.dark;
  };
}
