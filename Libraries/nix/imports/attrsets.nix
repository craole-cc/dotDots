{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        aggregation
        construction
        predicates
        selection
        transformation
        ;
    };
    flattened = access // aggregation // construction // predicates // selection // transformation;
  };

  inherit (lib) attrsets trivial;

  access = {
    inherit
      (attrsets)
      attrNames
      attrValues
      getAttr
      attrByPath
      getAttrFromPath
      collect
      foldlAttrs
      getBin
      ;
  };

  aggregation = {
    inherit
      (attrsets)
      intersectAttrs
      mergeAttrsList
      recursiveUpdate
      recursiveUpdateUntil
      zipAttrs
      zipAttrsWith
      ;
  };

  construction = {
    inherit
      (attrsets)
      genAttrs
      listToAttrs
      nameValuePair
      optionalAttrs
      ;
  };

  transformation = {
    inherit
      (attrsets)
      concatMapAttrs
      filterAttrs
      filterAttrsRecursive
      mapAttrs
      mapAttrs'
      mapAttrsRecursive
      mapAttrsToList
      removeAttrs
      setAttrByPath
      ;
    inherit (trivial) functionArgs;
  };

  selection = {
    inherit
      (attrsets)
      filterAttrs
      filterAttrsRecursive
      removeAttrs
      ;
  };

  predicates = {
    inherit
      (attrsets)
      hasAttr
      hasAttrByPath
      isAttrs
      isDerivation
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
