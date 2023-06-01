{
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.osu-lazer];

  home.persistence = {
    "/persist/home/craole".directories = [".local/share/osu"];
  };
}
