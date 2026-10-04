{lix, ...}: let
  inherit (lix.lists) unique;

  mkMergedList = args: let
    defaults = args.declared or args.default;
    overrides = args.declared or args.overrides;
  in {
    inherit defaults overrides;
    merged = unique (overrides ++ defaults);
  };
in {inherit mkMergedList;}
