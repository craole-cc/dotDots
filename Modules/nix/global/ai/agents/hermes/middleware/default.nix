{lix, ...} @ args: let
  inherit (lix.attrsets.aggregation) mergeShellFragments;

  fragments = [
    (import ./telegram args)
    (import ./whatsapp args)
    (import ./discord args)
  ];

  gatewayFragments = builtins.filter (fragment: fragment != "") (
    map (fragment: fragment.gatewayFragment or "") fragments
  );
in
  (mergeShellFragments fragments)
  // {
    # Middleware registers an optional runtime fragment instead of requiring a
    # central service definition to know every transport by name.
    prepare-hermes-gateway = builtins.concatStringsSep "\n" gatewayFragments;
  }
