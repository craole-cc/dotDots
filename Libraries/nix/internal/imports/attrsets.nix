{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        construction
        merging
        predicates
        transformation
        ;
    };
    flattened =
      {}
      // access
      // construction
      // merging
      // predicates
      // transformation
      // {};
  };

  inherit (lib) attrsets;

  access = {
    inherit
      (attrsets)
      attrNames
      attrValues
      getAttr
      attrByPath
      getAttrByPath
      collect
      foldlAttrs
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
      mapAttrsRecursive
      mapAttrsToList
      removeAttrs
      removeAttrByPath
      setAttrByPath
      ;
  };

  merging = {
    inherit
      (attrsets)
      intersectAttrs
      mergeAttrsList
      recursiveUpdate
      zipAttrs
      zipAttrsWith
      ;
  };

  predicates = {
    inherit
      (attrsets)
      hasAttr
      hasAttrByPath
      isAttrs
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
