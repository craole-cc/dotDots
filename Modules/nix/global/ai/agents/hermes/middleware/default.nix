args: let
  inherit (args.lix.attrsets.aggregation) mergeShellFragments;
in
  mergeShellFragments [
    (import ./telegram args)
    (import ./whatsapp args)
  ]
