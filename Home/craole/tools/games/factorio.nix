{
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = [pkgs.factorio];
    persistence = {
      "/persist/home/craole" = {
        allowOther = true;
        directories = [".factorio"];
      };
    };
  };
}
