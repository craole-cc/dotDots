{lib, ...}: let
  # inherit (lib.attrsets) genAttrs mapAttrs;
  # inherit (lib.lists) elem;
  # inherit (lib.modules) mkDefault mkIf;
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

  mkAdmin = name: {
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
  };

  exports = {inherit mkCore mkAdmin;};
in
  exports // {_rootAliases = exports;}
