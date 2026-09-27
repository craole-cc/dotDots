{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  # Shape of a single git identity entry.
  itemDefault = {
    name = null;
    email = null;
    settings = {};
  };

  default = [];

  resolve = {
    args ? {},
    git ? args.git or [],
  }:
    map (entry: recursiveUpdate itemDefault entry) git;
in {inherit default resolve;}
