{lib, ...}: let
  mkCore = {
    hosts,
    specialArgs,
    modulesPath,
    ...
  }:
    lib.mapAttrs (_name: host:
      lib.nixosSystem {
        inherit (host) system;
        specialArgs = specialArgs // {inherit host;};
        modules = [modulesPath] ++ (host.imports or []);
      })
    hosts;

  mkSudoRules = admins:
    map (name: {
      #> Apply this rule only to the named user.
      users = [name];

      #> Allow that user to run any command as any user/group, without password.
      #? Equivalent to: name ALL=(ALL:ALL) NOPASSWD: ALL
      commands = [
        {
          command = "ALL";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    })
    admins;

  exports = {inherit mkCore mkSudoRules;};
in
  exports // {_rootAliases = exports;}
