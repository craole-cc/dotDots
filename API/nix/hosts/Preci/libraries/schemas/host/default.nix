{lix, ...}: let
  __ = {inherit lix;};
  inherit (lix.schemas) declareFields resolveFields;
  inherit (lix.schemas.user) mkUsers;

  fields = {
    name = import ./name.nix __;
    applications = import ./applications.nix __;
    class = import ./class.nix __;
    description = import ./description.nix __;
    functionalities = import ./functionalities.nix __;
    id = import ./id.nix __;
    interface = import ./interface.nix __;
    localisation = import ./localisation.nix __;
    packages = import ./packages.nix __;
    paths = import ./paths.nix __;
    principals = import ./principals.nix __;
    specs = import ./specs.nix __;
    stateVersion = import ./stateVersion.nix __;
    system = import ./system.nix __;
  };
  default = declareFields fields;
  resolve = domain: resolveFields domain fields;

  mkHost = args: let
    resolved = resolve args;
    #? `mkUsers` returns the named views (`primary`, `secondary`, `defined`,
    #? ...). Modules also need the list of every principal as declared, so
    #? `all` is bound here rather than at each call site: one shape, two views.
    users = mkUsers resolved.principals;
    principals = users // {all = users.defined;};
  in
    resolved // {inherit principals;};
in
  fields // {inherit mkHost default;}
