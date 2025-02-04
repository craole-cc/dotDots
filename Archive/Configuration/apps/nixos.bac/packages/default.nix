# { config, pkgs, ... }:
{ ... }:

{
  imports = [
    ./app
    ./core
    ./style
    ./utility
    ./web
  ];
}
