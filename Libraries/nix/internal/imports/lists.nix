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
        reduction
        predicates
        selection
        transformation
        ;
    };
    flattened =
      {}
      // access
      // construction
      // reduction
      // predicates
      // selection
      // transformation
      // {};
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
      uniqueBy
      zipLists
      zipListsWith
      ;
  };

  selection = {
    inherit
      (lists)
      drop
      dropWhile
      filter
      partition
      splitAt
      sublist
      take
      takeWhile
      ;
  };

  reduction = {
    inherit
      (lists)
      concatLists
      concatMap
      foldl'
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
