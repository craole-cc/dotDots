{
  _,
  lib,
  ...
}: let
  inherit (_.modules.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.software) mkBoot mkNix mkLocale mkFonts;
  inherit (_.modules.home) mkUsers;
  inherit (_.modules.environment) mkEnvironment;
  inherit (_.modules.resolution) systems;

  mkCore = {
    hosts,
    specialArgs,
    src,
    ...
  }:
    lib.mapAttrs (_name: host: let
      inherit (specialArgs) inputs;
      # pkgs = with inputs.packages;
      #   if (host.packages.unstable or false)
      #   then nixpkgs-unstable.${host.system}
      #   else nixpkgs-stable.${host.system};
      # inherit (pkgs.stdenv.hostPlatform) system;
    in
      lib.nixosSystem {
        inherit (host) system;
        inherit specialArgs;
        # specialArgs = specialArgs // {inherit host system;};

        modules =
          [
            {
              imports = with inputs.modules.core; [home-manager];

              # First, configure nixpkgs with overlays and allowUnfree
              config = mkNix {inherit host inputs;};
            }

            # Now that pkgs is properly configured, use it in other modules
            ({pkgs, ...}: {
              config =
                mkBoot {inherit host pkgs;}
                // mkFileSystems {inherit host;}
                // mkNetwork {inherit host pkgs;}
                // mkLocale {inherit host;}
                // mkAudio {inherit host;}
                // mkFonts {inherit host pkgs;}
                // mkUsers {inherit host pkgs inputs src specialArgs;}
                // mkEnvironment {inherit host pkgs inputs;}
                // {};
            })
          ]
          ++ (host.imports or []);
      })
    hosts;

  exports = {inherit mkCore systems;};
in
  exports // {_rootAliases = exports;}
