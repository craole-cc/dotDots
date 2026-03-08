{
  _,
  lib,
  ...
}: let
  inherit (_.modules.core.environment) mkEnvironment mkLocale;
  inherit (_.modules.core.services) mkServices;
  inherit (_.modules.core.programs) mkPrograms;
  inherit (_.modules.core.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.core.software) mkNix mkBoot mkClean;
  inherit (_.modules.core.style) mkFonts;
  inherit (lib.modules) mkMerge;
  inherit (_.modules.core.users) mkUsers;
  mkHome = _.configuration.home.modules.mkConfig;

  mkConfig = {
    host,
    nixpkgs,
    inputs,
    specialArgs,
  }:
    [
      {inherit nixpkgs;}
      (
        {
          config,
          paths,
          pkgs,
          ...
        }:
          mkMerge [
            (mkNix {inherit host pkgs;})
            (mkNetwork {inherit host pkgs;})
            (mkBoot {inherit host pkgs;})
            (mkFileSystems {inherit host;})
            (mkLocale {inherit host;})
            (mkAudio {inherit host;})
            (mkFonts {inherit host pkgs;})
            # (mkStyle {inherit host pkgs;}) # TODO: Not ready, build errors
            (mkClean {inherit host;})
            (mkEnvironment {inherit config host pkgs inputs;})
            (mkServices {inherit config host;})
            (mkPrograms {inherit host;})
            (mkUsers {inherit host pkgs;})
            (mkHome {inherit host specialArgs paths;})
          ]
      )
    ]
    ++ (host.imports or []);

  exports = {
    inherit mkConfig;
    mkCoreConfig = mkConfig;
  };
in
  exports // {_rootAliases = {inherit (exports) mkCoreConfig;};}
