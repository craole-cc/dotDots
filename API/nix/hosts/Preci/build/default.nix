let
  host = import ./host.nix;
  users = import ./users;
in {inherit host users;}
