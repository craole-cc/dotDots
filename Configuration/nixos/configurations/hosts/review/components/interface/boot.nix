{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with config.dots.info.host.interface.boot;
{
  config.boot = {
    inherit timeout;
  };
}
