{ config, lib, ... }:
{
  imports = [
    ./libraries
    ./modules
    # ./packages
    ./assets

    ./sources # TODO: remove this after figuring out the infinite recursion issue
  ];

  options.admin = lib.mkOption { default = config.dot; };
}
