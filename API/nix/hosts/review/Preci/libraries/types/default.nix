{lix, ...}: let
  inherit (lix.attrsets) recursiveUpdate;
  types = import ./lib.nix {inherit lix;};

  user = import ./user {lix = lix // {inherit types;};};
  withUser = recursiveUpdate types {inherit user;};

  host = import ./host {lix = lix // {types = withUser;};};
  withHost = recursiveUpdate withUser {inherit host;};
in
  withHost
