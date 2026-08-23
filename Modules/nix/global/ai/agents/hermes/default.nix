{lix, ...} @ args: let
  inherit (lix.attrsets.aggregation) recursiveUpdate mergeShellFragments;

  environment = import ./environment args;
  middleware = import ./middleware (
    recursiveUpdate args (tools // {inherit sources;})
  );
  packages = import ./packages (
    args // {inherit middleware;}
  );
  inherit (packages) tools sources scripts;

  hooks = import ./hooks (
    recursiveUpdate args (
      recursiveUpdate environment {inherit tools;}
    )
  );
in
  mergeShellFragments [
    environment
    tools
    middleware
    scripts
    hooks
  ]
