{ config, ... }:
let
  inherit (config.dots.alpha) name;
in
{
  wsl = {
    enable = true;
    defaultUser = name;
    startMenuLaunchers = true;
  };
}
