{_, ...}: let
  exports = {
    inherit findFirstOrNull;
  };

  inherit (_.lists.access) head tail;

  /*
  Finds the first element in a list matching a predicate function,
  returning `null` if no element satisfies the predicate.

  Evaluates lazily and short-circuits as soon as a match is found.

  # Type:
  > findFirstOrNull :: (a -> Bool) -> [a] -> (a | Null)
  */
  findFirstOrNull = predicate: list:
    if list == []
    then null
    else if predicate (head list)
    then (head list)
    else findFirstOrNull predicate (tail list);
in
  exports // {__rootAliases = exports;}
