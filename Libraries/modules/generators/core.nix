{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (_.modules.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.software) mkBoot mkPkgs mkClean;
  inherit (_.modules.home) mkUsers;
  inherit (_.modules.environment) mkEnvironment mkFonts mkLocale;
  inherit (_.modules.resolution) systems system;

  mkSystem = {
    hosts,
    args,
    src,
    ...
  }:
    mapAttrs (
      _name: host: let
        class = host.class or "nixos";
        inherit (host) system;

        inherit (lib.lists) optionals;
        inherit (lib.modules) evalModules;
        inherit (args) normalizedInputs normalizedPackages src;
        inherit (args.normalizedInputs) nixpkgs home-manager nix-darwin;

        specialArgs = args // {inherit host system;};

        #~@ Modules
        modulesPath = "${nixpkgs}/nixos/modules";
        baseModules = import "${modulesPath}/module-list.nix";

        hmModules =
          if class == "darwin"
          then [home-manager.darwinModules.home-manager]
          else [home-manager.nixosModules.home-manager];

        hostModules = [
          (mkPkgs {inherit host normalizedInputs normalizedPackages;})
          (
            {pkgs, ...}:
              {}
              // mkNetwork {inherit host pkgs;}
              // mkBoot {inherit host pkgs;}
              // mkFileSystems {inherit host;}
              // mkLocale {inherit host;}
              // mkAudio {inherit host;}
              // mkFonts {inherit host pkgs;}
              // mkUsers {inherit host pkgs specialArgs src;}
              // mkEnvironment {inherit host pkgs normalizedPackages;}
              // mkClean {inherit host;}
              // {}
          )
        ];

        darwinModules = optionals (class == "darwin") [
          {
            nixpkgs.source = nixpkgs.outPath;
            system = {
              checks.verifyNixPath = false;
              darwinVersionSuffix = ".${nix-darwin.shortRev or nix-darwin.dirtyShortRev or "dirty"}";
              darwinRevision = nix-darwin.rev or nix-darwin.dirtyRev or "dirty";
            };
          }
        ];

        moduleArgs = [
          {
            config = {
              _module.args = {
                inherit baseModules hostModules darwinModules modulesPath;
              };
              nixpkgs.flake.source = nixpkgs.outPath;
            };
          }
        ];

        moduleEval = evalModules {
          specialArgs =
            specialArgs
            // {
              inherit baseModules modulesPath;
              modules = hostModules;
            };
          modules =
            baseModules
            ++ hmModules
            ++ hostModules
            ++ moduleArgs
            ++ darwinModules
            ++ (host.imports or []);
        };
      in
        if class == "darwin"
        then (moduleEval // {system = moduleEval.config.system.build.toplevel;})
        else moduleEval
    )
    hosts;

  exports = {inherit mkSystem systems system;};
in
  exports // {_rootAliases = exports;}
