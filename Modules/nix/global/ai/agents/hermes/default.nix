args: let
  environment = import ./environment args;
  packages = import ./packages args;
  hooks = import ./hooks (args // environment // packages);
in
  environment // packages // hooks
