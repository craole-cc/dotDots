{
  # config,
  ...
}: {
  # imports = lix.filesystem.importers.importAllPaths ./.;
  imports = [
    ./common
    ./config.nix
    ./environment
    ./manager
    ./options.nix
  ];
}
