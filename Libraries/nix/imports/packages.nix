{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit access construction metadata predicates transformation;
    };
    flattened = {} // access // construction // metadata // predicates // transformation // {};
  };

  inherit (lib) meta;

  access = {
    inherit
      (meta)
      getDarwinApp
      getDarwinApp'
      getExe
      getExe'
      getLicenseFromSpdxId
      getLicenseFromSpdxIdOr
      ;
  };

  construction = {
    inherit
      (meta)
      addMetaAttrs
      appendToName
      dontDistribute
      hiPrio
      lowPrio
      setName
      setPrio
      updateName
      ;
  };

  metadata = {
    inherit (meta) cpeFullVersionWithVendor defaultPriority licensesSpdx;
  };

  predicates = {inherit (meta) availableOn platformMatch;};

  transformation = {inherit (meta) hiPrioSet lowPrioSet mapDerivationAttrset;};
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
