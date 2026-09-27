{
  lib,
  lix,
  ...
}: let
  schemas = import ./lib.nix {inherit lib lix;};
  user = import ./user {
    inherit lib;
    lix = lix // {inherit schemas;};
  };
  host = import ./host {
    inherit lib;
    lix = lix // {schemas = schemas // user;};
  };
in {schemas = schemas // user // host;}
