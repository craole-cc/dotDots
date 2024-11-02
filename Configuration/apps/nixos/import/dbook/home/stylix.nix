{pkgs, ...}: let
  stylix = pkgs.fetchFromGitHub {
    owner = "danth";
    repo = "stylix";
    rev = "master";
    sha256 = "W9Y/+K4L7JcF5xcXO4MVGQk/0DgzHrp/IjlHyLeYExY=";
  };
in {
  imports = [
    (import stylix).homeManagerModules.stylix
  ];
}
