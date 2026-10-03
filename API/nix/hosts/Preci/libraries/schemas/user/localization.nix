{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {};

  resolve = {args ? {}}:
    recursiveUpdate default (args.localization or {});
in {inherit default resolve;}
