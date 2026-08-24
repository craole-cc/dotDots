{lix, ...} @ args: let
  inherit (lix.attrsets.aggregation) recursiveUpdate mergeShellFragments;

  environment = import ./environment args;
  packages = import ./packages (recursiveUpdate args environment);
  inherit (packages) scripts;

  hooks = import ./hooks (
    recursiveUpdate args (
      recursiveUpdate environment {inherit packages;}
    )
  );
in
  mergeShellFragments [
    environment
    scripts
    hooks
  ]
