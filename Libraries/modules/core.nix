{
  _,
  lib,
  ...
}: let
  inherit (_.modules.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.software) mkNix mkLocale mkFonts;
  inherit (_.modules.home) mkUsers;
  inherit (_.modules.resolution) systems;

  mkCore = {
    hosts,
    specialArgs,
    modulesPath,
    ...
  }:
    lib.mapAttrs (_name: host: let
      inherit (specialArgs) inputs;
      pkgs = with inputs.packages;
        if (host.packages.unstable or false)
        then nixpkgs-unstable.${host.system}
        else nixpkgs-stable.${host.system};
      inherit (pkgs.stdenv.hostPlatform) system;
    in
      lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs // {inherit host system;};
        imports = with inputs.modules.core; [home-manager];
        modules =
          [
            {
              config =
                mkNix {inherit host inputs;}
                // mkAudio {inherit host;}
                // mkFileSystems {inherit host;}
                // mkNetwork {inherit host pkgs;}
                // mkLocale {inherit host;}
                // mkFonts {inherit host;}
                # // mkUsers {inherit host pkgs inputs;}
                // {};
            }
          ]
          ++ (host.imports or []);
      })
    hosts;

  # mkSudoRules = admins:
  #   map (name: {
  #     #> Apply this rule only to the named user.
  #     users = [name];

  #     #> Allow that user to run any command as any user/group, without password.
  #     #? Equivalent to: name ALL=(ALL:ALL) NOPASSWD: ALL
  #     commands = [
  #       {
  #         command = "ALL";
  #         options = ["SETENV" "NOPASSWD"];
  #       }
  #     ];
  #   })
  #   admins;

  exports = {inherit mkCore systems;};
in
  exports // {_rootAliases = exports;}
