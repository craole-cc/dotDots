{
  lix,
  pkgs,
  ...
}: {
  imports = lix.filesystem.importers.importAllPaths ./.;

  config = {
    stylix.icons = {
      enable = true;
      package = null;
      light = pkgs.candy-icons.name;
      dark = pkgs.candy-icons.name;
    };
    programs.regreet = {
      enable = true;
      name = pkgs.candy-icons.name;
      package = pkgs.candy-icons;
    };
  };
}
