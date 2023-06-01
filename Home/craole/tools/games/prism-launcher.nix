{
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.prismlauncher];

  home.persistence = {
    "/persist/home/craole".directories = [".local/share/PrismLauncher"];
  };
}
