{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;

  default = {
    kernel = "linuxPackages_latest";
    shells = [];
    coding = [];
    common = [];
    launchers = [];
  };

  resolve = args:
    recursiveUpdate default (args.packages or {});
in {inherit default resolve;}
