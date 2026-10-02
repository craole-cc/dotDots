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
  fields = {
    name = import ./name.nix libs;
    applications = import ./applications.nix libs;
    class = import ./class.nix libs;
    description = import ./description.nix libs;
    functionalities = import ./functionalities.nix libs;
    id = import ./id.nix libs;
    interface = import ./interface.nix libs;
    localization = import ./localization.nix libs;
    packages = import ./packages.nix libs;
    paths = import ./paths.nix libs;
    principals = import ./principals.nix libs;
    specs = import ./specs.nix libs;
    stateVersion = import ./stateVersion.nix libs;
    system = import ./system.nix libs;
  };
  default = lix.schemas.fields.default fields;
  resolve = args: lix.schemas.fields.resolve {inherit args fields;};
  constructors = import ./lib.nix {inherit lib lix resolve;};
in
  fields
  // {inherit default resolve;}
  // constructors
