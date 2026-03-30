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
      head
      init
      last
      length
      tail
      findFirst
      findFirstIndex
      ;
  };

  construction = {
    inherit
      (lists)
      genList
      range
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
      count
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
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
