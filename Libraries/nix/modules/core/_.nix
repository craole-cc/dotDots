{
  _,
  lib,
  ...
}: let
  inherit (_.modules._) mkHome;
  inherit (_.modules.core.environment) mkEnvironment mkLocale;
  inherit (_.modules.core.hardware) mkAudio mkFileSystems mkNetwork mkBoot;
  inherit (_.modules.core.programs) mkPrograms;
  inherit (_.modules.core.services) mkServices;
  inherit (_.modules.core.software) mkNix mkClean;
  inherit (_.modules.core.style) mkFonts;
  inherit (_.modules.core.users) mkUsers;
  inherit (lib.modules) mkMerge;

  exports = {
    inherit mkCore;
    inherit
      mkAudio
      mkBoot
      mkClean
      mkEnvironment
      mkFileSystems
      mkFonts
      mkHome
      mkLocale
      mkMerge
      mkNetwork
      mkNix
      mkPrograms
      mkServices
      mkUsers
      ;
  };

  mkCore = {
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
in
  exports
  // {
    _rootAliases = {
      # inherit (exports) mkCore;
    };
  }
