{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
    machine = null;
    cpu = {
      arch = null;
      brand = null;
    };
  };

  resolve = {args ? {}}:
    recursiveUpdate default (args.specs or {});
in {inherit default resolve;}
