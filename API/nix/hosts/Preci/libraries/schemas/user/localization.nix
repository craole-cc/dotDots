{lib, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  default = {};

  resolve = {args ? {}}:
    recursiveUpdate default (args.localization or {});
in {inherit default resolve;}
