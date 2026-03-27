{lix, ...}: {
  imports = lix.filesystem.importers.importAllPaths ./.;

  config = {
    programs.regreet = {
      enable = true;
    };
  };
}
