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
    args ? {},
    class ? "nixos",
    inputs ? {},
    modules ? [],
    specialArgs ? {},
    ...
  }: let
    #~@ Inputs
    args' = args // specialArgs // {inherit inputs;};
    nixpkgs = inputs.nixpkgs or inputs.nixPackages or args'.inputs.modules.core.nixpkgs or (throw "No `nixpkgs` input found");
    darwin = inputs.darwin or inputs.nixDarwin or args'.inputs.modules.core.darwin or (throw "No `nix-darwin` input found");
    lib = nixpkgs.lib;
    home-manager = inputs.home-manager or inputs.nixHomeManager or args'.inputs.modules.core.home-manager or {};

    #~@ Imports
    inherit (lib.lists) optionals;
    inherit (lib.modules) evalModules;

    #~@ Modules
    modulesPath = "${nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    hostModules = modules;

    #~@ System
    eval = evalModules {
      class =
        if class == "darwin"
        then "darwin"
        else "nixos";

      specialArgs = args' // {inherit modulesPath home-manager;};

      modules =
        baseModules
        ++ hostModules
        ++ optionals (home-manager != null) [
          (
            if class == "darwin"
            then home-manager.darwinModules.home-manager
            else home-manager.nixosModules.home-manager
          )
        ]
        ++ [
          {
            config = {
              _module.args = {inherit baseModules modules;};
              nixpkgs.flake.source = nixpkgs.outPath;
            };
          }
        ]
        ++ optionals (class == "darwin") [
          {
            config = {
              nixpkgs.source = nixpkgs.outPath;
              system = {
                checks.verifyNixPath = false;
                darwinVersionSuffix = ".${darwin.shortRev or darwin.dirtyShortRev or "dirty"}";
                darwinRevision = darwin.rev or darwin.dirtyRev or "dirty";
              };
            };
          }
        ];
    };
  in
    if class == "darwin"
    then (eval // {system = eval.config.system.build.toplevel;})
    else eval;

  mkCoreNew = {
    hosts,
    args,
    inputs,
    src,
    ...
  }:
    mapAttrs (_name: host: let
      systemBuilder = mkSystem;
      specialArgs =
        args
        // {
          inherit host;
          inherit (host) system;
        };
      inherit (specialArgs) inputs src;
    in
      systemBuilder {
        inputs = specialArgs.rawInputs;
        inherit specialArgs;
        modules =
          [
            {
              imports = [inputs.nixHomeManager.nixosModules.home-manager];
              config = mkPkgs {inherit host inputs;};
            }
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
                // mkEnvironment {inherit host pkgs inputs;}
                // mkClean {inherit host;}
                // {};
            })
          ]
          ++ (host.imports or []);
      })
    hosts;

  mkCore = {
    hosts,
    args,
    inputs,
    src,
    ...
  }:
    mapAttrs (_name: host: let
      systemBuilder = lib.nixosSystem;
      specialArgs =
        args
        // {
          inherit host;
          inherit (host) system;
        };
      inherit (specialArgs) inputs src;
    in
      systemBuilder {
        inherit specialArgs;
        modules =
          [
            {
              imports = with specialArgs.inputs.modules.core; [home-manager];

              #> Configure nixpkgs with overlays and allowUnfree
              config = mkPkgs {inherit host inputs;};
            }
            ({pkgs, ...}: {
              config =
                {}
                // mkBoot {inherit host pkgs;}
                // mkFileSystems {inherit host;}
                // mkNetwork {inherit host pkgs;}
                // mkLocale {inherit host;}
                // mkAudio {inherit host;}
                // mkFonts {inherit host pkgs;}
                // mkUsers {inherit host inputs pkgs specialArgs src;}
                // mkEnvironment {inherit host pkgs inputs;}
                // mkClean {inherit host;}
                // {};
            })
          ]
          ++ (host.imports or []);
      })
    hosts;

  exports = {inherit mkSystem mkCore systems system;};
in
  exports // {_rootAliases = exports;}
