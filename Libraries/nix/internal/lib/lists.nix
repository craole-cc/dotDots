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
        filtering
        folding
        predicates
        searching
        slicing
        transformation
        ;
    };
    flattened =
      {}
      // access
      // construction
      // filtering
      // folding
      // predicates
      // searching
      // slicing
      // transformation
      // {};
  };

  access = {
    inherit
      (lib.lists)
      elemAt
      head
      init
      last
      tail
      ;
  };

  construction = {
    inherit
      (lib.lists)
      genList
      range
      replicate
      singleton
      toList
      ;
  };

  transformation = {
    inherit
      (lib.lists)
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

  slicing = {
    inherit
      (lib.lists)
      drop
      dropWhile
      splitAt
      sublist
      take
      takeWhile
      ;
  };

  searching = {
    inherit
      (lib.lists)
      findFirst
      findFirstIndex
      ;
  };

  filtering = {
    inherit
      (lib.lists)
      filter
      partition
      ;
  };

  folding = {
    inherit
      (lib.lists)
      concatLists
      concatMap
      count
      foldl'
      foldr
      ;
  };

  predicates = {
    inherit
      (lib.lists)
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
