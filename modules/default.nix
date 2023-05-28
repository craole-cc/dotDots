{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./boot
    ./fileSystems
    ./networking
    ./per-user
  ];
}
