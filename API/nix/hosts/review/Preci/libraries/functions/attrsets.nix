{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;
  inherit (lix.lists) foldl' reverseList;

  mkMergedAttrs = args: let
    #? These must read *different* attributes. Binding both from `declared`
    #? silently makes the overrides equal the defaults, which merges a value
    #? into itself and looks like it worked.
    #?
    #? `declared` means "both sides": it backs whichever of the two explicit
    #? spellings was not given, with `{}` as the last resort so an absent
    #? attribute resolves to "nothing declared" rather than throwing.
    #? `requested` is the preferred name for the user side, because that is
    #? the vocabulary `context/` speaks.
    #?
    #? The parentheses matter. `a.x or b.y` leaves the trailing lookup
    #? unguarded, so reaching it throws on a missing attribute instead of
    #? falling through -- `args.declared or args.default` fails precisely when
    #? `declared` is absent and `default` is what the caller passed. Grouping
    #? the right-hand side makes each fallback a complete guarded expression.
    defaults = args.default or (args.declared or {});
    #? `overrides` is a *list* of attrset overrides, not one attrset: each
    #? entry is folded in turn, and the order is the priority. `{}` here would
    #? reach `reverseList` and throw, so the empty case has to be `[]`.
    overrides = args.requested or (args.overrides or []);
  in {
    inherit defaults overrides;
    #? Principal order is significant: earlier principals have priority, so the
    #? later ones are folded in first and the earliest declaration wins.
    merged =
      foldl'
      recursiveUpdate
      defaults
      (reverseList overrides);
  };
in {inherit mkMergedAttrs;}
