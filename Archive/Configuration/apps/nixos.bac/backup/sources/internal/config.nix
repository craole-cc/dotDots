{ config, lib, ... }:
let
  inherit (config.dots.paths) dots bins;
in
{
  config = {
    environment = {
      variables.DOTS = dots;
      pathsToLink = bins;
    };
  };
}
