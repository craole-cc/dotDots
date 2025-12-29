{lix, ...}: {
  imports =
    lix.filesystem.importers.importAll ./.
    ++ [./atuin];
}
