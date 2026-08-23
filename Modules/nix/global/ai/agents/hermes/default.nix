args: let
  environment = import ./environment args;
  packages = import ./packages args;
  middleware = import ./middleware (args // packages);
  hooks = import ./hooks (args // environment // packages);
in
  environment
  // packages
  // middleware
  // hooks
