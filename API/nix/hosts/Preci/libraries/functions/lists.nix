{lix, ...}: let
  inherit (lix.lists) unique;

  mkMergedList = args: let
    #? See `mkMergedAttrs` for why these read different attributes.
    #?
    #? `declared` means "both sides": it backs whichever explicit spelling was
    #? not given, with the empty list as the last resort so an absent attribute
    #? resolves to "nothing declared" rather than throwing. `requested` leads
    #? because that is the vocabulary `context/` speaks.
    #?
    #? The parentheses matter. `a.x or b.y` leaves the trailing lookup
    #? unguarded, so reaching it throws on a missing attribute instead of
    #? falling through -- `args.declared or args.default` fails precisely when
    #? `declared` is absent and `default` is what the caller passed. Grouping
    #? the right-hand side makes each fallback a complete guarded expression.
    defaults = args.default or (args.defaults or (args.declared or []));
    overrides = args.overrides or (args.provided or (args.requested or []));
  in {
    inherit defaults overrides;
    #? `overrides` first: the list order *is* the priority, so the requester's
    #? preferences lead and the host's declarations fill in behind them.
    ordered = unique (overrides ++ defaults);
  };
in {inherit mkMergedList;}
