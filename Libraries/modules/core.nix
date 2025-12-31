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

  # mkSystem = {
  #   inputsModules,
  #   nixpkgs,
  #   args ? {},
  #   class ? "nixos",
  #   hostModules ? [],
  #   specialArgs ? {},
  #   ...
  # }: let
  #   #~@ Inputs
  #   args' = args // specialArgs // {inherit inputs;};
  #   darwin =
  #     if (class == "darwin")
  #     then inputs.nix-darwin
  #     else (throw "No `nix-darwin` input found");

  #   #~@ Imports
  #   lib = nixpkgs.lib;
  #   inherit (lib.lists) optionals;
  #   inherit (lib.modules) evalModules;

  #   #~@ Modules
  #   modulesPath = "${nixpkgs}/nixos/modules";
  #   baseModules = import "${modulesPath}/module-list.nix";

  #   #~@ System
  #   eval = evalModules {
  #     class =
  #       if class == "darwin"
  #       then "darwin"
  #       else "nixos";

  #     specialArgs = args' // {inherit modulesPath;};

  #     modules =
  #       baseModules
  #       ++ hostModules
  #       ++ [
  #         {
  #           config = {
  #             _module.args = {inherit baseModules modules;};
  #             nixpkgs.flake.source = nixpkgs.outPath;
  #           };
  #         }
  #       ]
  #       ++ optionals (class == "darwin") [
  #         {
  #           config = {
  #             nixpkgs.source = nixpkgs.outPath;
  #             system = {
  #               checks.verifyNixPath = false;
  #               darwinVersionSuffix = ".${darwin.shortRev or darwin.dirtyShortRev or "dirty"}";
  #               darwinRevision = darwin.rev or darwin.dirtyRev or "dirty";
  #             };
  #           };
  #         }
  #       ];
  #   };
  # in
  #   if class == "darwin"
  #   then (eval // {system = eval.config.system.build.toplevel;})
  #   else eval;

  mkSystem = {
    hosts,
    args,
    src,
    ...
  }:
    mapAttrs (
      _name: host: let
        specialArgs =
          args
          // {
            inherit host;
            inherit (host) system;
          };

        inherit (lib.lists) optionals;
        inherit (lib.modules) evalModules;
        inherit (args) normalizedInputs normalizedPackages src;
        inherit (args.inputs.modules) nixpkgs home-manager nix-darwin;

        class = host.class or "nixos";

        #~@ Modules
        modulesPath = "${nixpkgs}/nixos/modules";
        baseModules = import "${modulesPath}/module-list.nix";
        homeModules =
          if class == "darwin"
          then [home-manager.darwinModules.home-manager]
          else [home-manager.nixosModules.home-manager];
        hostModules = [
          {config = mkPkgs {inherit host normalizedInputs normalizedPackages;};}
          ({pkgs, ...}: {
            config =
              {}
              // mkBoot {inherit host pkgs;}
              // mkFileSystems {inherit host;}
              // mkNetwork {inherit host pkgs;}
              // mkLocale {inherit host;}
              // mkAudio {inherit host;}
              // mkFonts {inherit host pkgs;}
              // mkUsers {inherit host pkgs specialArgs src;}
              // mkEnvironment {inherit host pkgs normalizedInputs;}
              // mkClean {inherit host;}
              // {};
          })
        ];
        darwinModules = optionals (class == "darwin") [
          {
            config = {
              nixpkgs.source = nixpkgs.outPath;
              system = {
                checks.verifyNixPath = false;
                darwinVersionSuffix = ".${nix-darwin.shortRev or nix-darwin.dirtyShortRev or "dirty"}";
                darwinRevision = nix-darwin.rev or nix-darwin.dirtyRev or "dirty";
              };
            };
          }
        ];
        moduleArgs = [
          {
            config = {
              _module.args = {inherit baseModules hostModules darwinModules;};
              nixpkgs.flake.source = nixpkgs.outPath;
            };
          }
        ];
        moduleEval = evalModules {
          inherit specialArgs;
          modules =
            baseModules
            ++ homeModules
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
