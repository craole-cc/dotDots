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
        aggregation
        predicates
        selection
        transformation
        ;
    };
    flattened =
      access
      // aggregation
      // construction
      // predicates
      // selection
      // transformation;
  };

  inherit (lib) lists;

  access = {
    inherit
      (lists)
      elemAt
      count
      findFirst
      findFirstIndex
      head
      init
      last
      length
      tail
      ;
  };

  construction = {
    inherit
      (lists)
      genList
      range
      optional
      optionals
      replicate
      singleton
      toList
      ;
  };

  transformation = {
    inherit
      (lists)
      flatten
      flattenDepth
      imap0
      imap1
      naturalSort
      reverseList
      sort
      sortOn
      unique
      uniqueStrings
      zipLists
      zipListsWith
      ;
  };

  selection = {
    inherit
      (lists)
      drop
      dropEnd
      filter
      partition
      sublist
      take
      takeEnd
      ;
  };

  aggregation = {
    inherit
      (lists)
      concatLists
      concatMap
      foldl'
      foldl
      foldr
      ;
  };

  predicates = {
    inherit
      (lists)
      all
      any
      elem
      isList
      allUnique
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
