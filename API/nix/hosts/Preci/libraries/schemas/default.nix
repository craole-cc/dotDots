{
  lib,
  lix,
  #? The dotDots repository root, used to reach the shared vocabulary data
  #? leaves under `Libraries/nix/lists/enums/data/`. Null when the schemas
  #? are evaluated outside a checkout, in which case each field falls back to
  #? its built-in vocabulary.
  sources ? null,
  ...
}: let
  libs = {
    inherit lib lix sources;
  };
  schemas = import ./lib.nix {inherit lib lix;};
  user = import ./user {
    inherit lib sources;
    lix = lix // {inherit schemas;};
  };
  host = import ./host {
    inherit lib sources;
    lix = lix // {schemas = schemas // user;};
  };
in {schemas = schemas // user // host;}
