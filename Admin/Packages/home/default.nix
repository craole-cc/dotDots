{lix, ...}: {
  imports = lix.filesystem.importers.importAll ./.;
  # imports = lix.filesystem.importers.importAll ./browser;
  # imports = [
  #   # ./browser
  #   # ./editor
  #   # ./common
  # ];
}
