{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  # Shape of a single git identity entry.
  itemDefault = {
    name = null;
    email = null;
    settings = {};
  };

  default = [];

  resolve = {git ? args.git or [], ...} @ args:
    map (entry: recursiveUpdate itemDefault entry) git;
in {inherit default resolve;}
