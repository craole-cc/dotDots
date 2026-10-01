{
  lib,
  lix,
  ...
}: let
  libs = {inherit lib lix;};
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
