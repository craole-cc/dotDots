# lib: let
#   user = (import ./name.nix)
#     // (import ./role.nix)
#     // (import ./uid.nix)
#     // (import ./autoLogin.nix)
#     // (import ./description.nix)
#     // (import ./paths.nix)
#     // (import ./git.nix)
#     // (import ./interface.nix)
#     // (import ./applications.nix)
#     // (import ./capabilities.nix)
#     // (import ./password.nix) # Prefer hashedPassword
#     // {
#       # password = null;
#       hashedPassword = null; #? Must be set, encourage howto
#       localization = {}; #? this is if the user is of a different locale than the host
#       };
# in
#   (import ./lib.nix (lib // {inherit default;})) #TODO: retire this
#   // {inherit user;}
# ok. before getting to the more complex nested one. i want to mirror the begavior in users, which actuall will matter to host.
{
  lib,
  lix,
  ...
}: let
  libs = {inherit lib lix;};
  fields = {
    applications = import ./applications.nix libs;
    autoLogin = import ./autoLogin.nix libs;
    capabilities = import ./capabilities.nix libs;
    description = import ./description.nix libs;
    enable = import ./enable.nix libs;
    git = import ./git.nix libs;
    interface = import ./interface.nix libs;
    localization = import ./localization.nix libs;
    name = import ./name.nix libs;
    packages = import ./packages.nix libs;
    hashedPassword = import ./hashedPassword.nix libs;
    paths = import ./paths.nix libs;
    role = import ./role.nix libs;
    uid = import ./uid.nix libs;
  };
  default = lix.schemas.fields.default fields;
  resolve = args: lix.schemas.fields.resolve {inherit args fields;};
  constructors = import ./lib.nix {inherit lib lix resolve;};
in
  fields
  // {inherit default resolve;}
  // constructors
