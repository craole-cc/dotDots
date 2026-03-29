{lib, ...}: {
  inherit
    (lib.lists)
    #~@ Basic access
    head
    tail
    last
    init
    elemAt
    #~@ Construction
    singleton
    toList
    range
    genList
    replicate
    #~@ Transformation
    flatten
    flattenDepth
    reverseList
    sort
    sortOn
    naturalSort
    unique
    uniqueBy
    imap0
    imap1
    zipLists
    zipListsWith
    #~@ Slicing
    take
    drop
    sublist
    splitAt
    takeWhile
    dropWhile
    #~@ Searching
    findFirst
    findFirstIndex
    #~@ Filtering
    filter
    partition
    #~@ Folding / reduction
    foldl'
    foldr
    concatMap
    concatLists
    count
    #~@ Predicates
    isList
    elem
    any
    all
    ;
  inherit
    (lib.types)
    listOf
    nonEmptyListOf
    ;
}
