# {lix, ...}: let
#   inherit (lix.attrsets) recursiveUpdate;
#   schemas = import ./lib.nix {inherit lix;};
#   user = import ./user {lix = lix // {inherit schemas;};};
#   withUser = recursiveUpdate schemas {inherit user;};
#   host = import ./host {lix = lix // {schemas = withUser;};};
#   withHost = recursiveUpdate withUser {inherit host;};
# in
#   withHost
{
  lix,
  mkLix,
  ...
}: let
  schemas = import ./lib.nix {inherit lix;};

  user = import ./user (mkLix {inherit schemas;});
  withUser = mkLix (schemas // {inherit user;});

  host = import ./host (mkLix {schemas = withUser.lix;});
  withHost = mkLix (withUser.lix // {inherit host;});
in
  withHost.lix
