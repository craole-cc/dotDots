{
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.sublime-music];
  home.persistence = {
    "/persist/home/craole".directories = [".config/sublime-music"];
  };
}
