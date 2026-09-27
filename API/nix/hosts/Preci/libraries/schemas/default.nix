{
  lib,
  lix,
  ...
}: let
  common = import ./lib.nix {inherit lib lix;};
  user = import ./user ({inherit lib lix;} // common);
  host = import ./host ({inherit lib lix;} // common // user);
in {schemas = common // user // host;}
