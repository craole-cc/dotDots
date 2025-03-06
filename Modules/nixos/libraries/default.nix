{ config, lib, ... }:
{
  imports = [
    ./helpers.nix
    ./fetchers.nix
    ./filesystem.nix
    ./lists.nix
  ];

  options.dib = lib // config.DOTS.lib;
}
