{
  lix,
  pkgs,
  ...
}: {
  imports = lix.filesystem.importers.importAllPaths ./.;

  config = {
    stylix.icons = {
      enable = true;
      package = pkgs.candy-icons;
      light = pkgs.candy-icons.name;
      dark = pkgs.candy-icons.name;
    };
    programs.regreet = {
      enable = true;
      # iconTheme = lix.lib.mkDefault {
      #   name = pkgs.candy-icons.name;
      #   package = pkgs.candy-icons;
      # };
    };
  };
}
