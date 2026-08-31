{
  # config,
  ...
}: {
  # imports = lix.filesystem.traversal.importAllPaths ./.;
  imports = [
    ./common
    ./config.nix
    ./environment
    ./manager
    ./options.nix
  ];
}
