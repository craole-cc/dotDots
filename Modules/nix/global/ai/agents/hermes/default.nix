args: let
  inherit (args.lix.attrsets.aggregation) recursiveUpdate;
  environment = import ./environment args;
  packages = import ./packages args;
  middleware = import ./middleware (recursiveUpdate args packages);
  hooks = import ./hooks (recursiveUpdate args (recursiveUpdate environment packages));
in
  environment
  // packages
  // middleware
  // hooks
