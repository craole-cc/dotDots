{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {};

  resolve = args:
    recursiveUpdate default (args.localisation or {});
in {inherit default resolve;}
