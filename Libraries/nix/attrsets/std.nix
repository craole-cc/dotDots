{lib, ...}: {
  inherit
    (lib.attrsets)
    #~@ Resolution
    attrNames
    attrValues
    getAttr
    getAttrByPath
    attrByPath
    setAttrByPath
    removeAttrByPath
    #~@ Construction
    genAttrs
    listToAttrs
    nameValuePair
    optionalAttrs
    #~@ Transformation
    mapAttrs
    mapAttrsToList
    mapAttrsRecursive
    concatMapAttrs
    filterAttrs
    filterAttrsRecursive
    removeAttrs
    #~@ Merging / combining
    recursiveUpdate
    mergeAttrsList
    zipAttrs
    zipAttrsWith
    intersectAttrs
    #~@ Folding
    foldlAttrs
    collect
    #~@ Predicates
    hasAttr
    hasAttrByPath
    isAttrs
    ;

  inherit
    (lib.types)
    attrs
    attrsOf
    ;
}
