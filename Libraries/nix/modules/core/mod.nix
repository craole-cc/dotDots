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
  inherit (lib.lists) optionals;
  inherit (_.modules.core.users) mkUsers;
  mkHomeUsers = _.modules.home.users.mkUsers;

  mkNixPkgs = {
    host,
    config,
    overlays,
    inputs,
  }:
    {
      hostPlatform = host.system;
      inherit config overlays;
    }
    // (
      with inputs.nixpkgs; (
        if (host.class or "nixos") == "darwin"
        then {source = outPath;}
        else {flake.source = outPath;}
      )
    );

  mkCoreMods = {
    class,
    inputs,
  }:
    (
      if class == "darwin"
      then [
        (inputs.home-manager.darwinModules.home-manager or {})
        (inputs.stylix.darwinModules.stylix or {})
      ]
      else [
        (inputs.home-manager.nixosModules.home-manager or {})
        (inputs.stylix.nixosModules.stylix or {})
        (inputs.catppuccin.nixosModules.default or {})
        (inputs.chaotic.nixosModules.default or {})
      ]
    )
    ++ optionals (class == "darwin") [
      {
        system = {
          checks.verifyNixPath = false;
          darwinVersionSuffix = ".${
            inputs.nix-darwin.shortRev or
            inputs.nix-darwin.dirtyShortRev or
            "dirty"
          }";
          darwinRevision =
            inputs.nix-darwin.rev or inputs.nix-darwin.dirtyRev or "dirty";
        };
      }
    ]
    ++ [];

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
            # (mkHome {inherit host specialArgs mkHomeModuleApps paths;})
          ]
      )
    ]
    ++ (host.imports or []);

  exports = {inherit mkCore mkCoreMods mkNixPkgs;};
in
  exports // {_rootAliases = exports;}
