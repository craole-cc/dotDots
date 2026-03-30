{lib, ...}: let
  __exports =
    {
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
    }
    // access
    // construction
    // filtering
    // folding
    // predicates
    // searching
    // slicing
    // transformation
    // {};

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
  __exports
