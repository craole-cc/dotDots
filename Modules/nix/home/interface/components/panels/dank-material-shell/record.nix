{lix, ...}: let
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  record = lix.toolkit.records.dms-shell;
  bins = rec {
    dms = record.paths.executable;
    dmsCall = "${dms} ipc call";
    dmsSet = "${dmsCall} settings set";
  };
in
  recursiveUpdate record {
    inherit bins;
    binaries = bins;
  }
