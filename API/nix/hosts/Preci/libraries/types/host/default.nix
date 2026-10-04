{lix, ...}: let
  __ = {inherit lix;};
  inherit (lix.schemas) declareFields resolveFields;
  inherit (lix.schemas.user) mkUsers;

  fields = {
    name = import ./name.nix __;
    cpu = import ./cpu.nix __;
    applications = import ./applications.nix __;
    class = import ./class.nix __;
    description = import ./description.nix __;
    functionalities = import ./functionalities.nix __;
    id = import ./id.nix __;
    interface = import ./interface.nix __;
    kernel = import ./kernel.nix __;
    localisation = import ./localisation.nix __;
    packages = import ./packages.nix __;
    paths = import ./paths.nix __;
    principals = import ./principals.nix __;
    specs = import ./specs.nix __;
    stateVersion = import ./stateVersion.nix __;
    system = import ./system.nix __;
    type = import ./type.nix __;
  };
  default = declareFields fields;
  resolve = domain: resolveFields domain fields;

  mkHost = args: let
    resolved = resolve args;
    #? `mkUsers` already exposes the declared list as `defined`, alongside the
    #? named views (`primary`, `secondary`, ...). No second alias is bound
    #? here: `all` collided with `lib.lists.all` and duplicated `defined`.
    users = mkUsers resolved.principals;
  in
    resolved // {principals = users;};
in
  fields // {inherit mkHost default;}
