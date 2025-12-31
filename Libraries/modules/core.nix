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
    inputs,
    nixpkgs,
    home-manager,
    args ? {},
    class ? "nixos",
    modules ? [],
    specialArgs ? {},
    ...
  }: let
    #~@ Inputs
    args' = args // specialArgs // {inherit inputs;};
    darwin =
      if (class == darwin)
      then inputs.darwin
      else (throw "No `nix-darwin` input found");

    #~@ Imports
    lib = nixpkgs.lib;
    inherit (lib.lists) optionals;
    inherit (lib.modules) evalModules;

    #~@ Modules
    modulesPath = "${nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";
    hostModules = modules;
    homeModules =
      if class == "darwin"
      then home-manager.darwinModules.home-manager
      else home-manager.nixosModules.home-manager;

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
        ++ homeModules
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

  mkCore = {
    hosts,
    args,
    src,
    class ? "nixos",
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
      inherit (args) src inputs;
      inherit (args.inputs.modules) home-manager;
    in
      systemBuilder {
        inherit specialArgs class inputs;
        modules =
          [
            (
              if class == "darwin"
              then home-manager.darwinModules.home-manager
              else home-manager.nixosModules.home-manager
            )
          ]
          [
            {config = mkPkgs {inherit host inputs;};}
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

  exports = {inherit mkSystem mkCore systems system;};
in
  exports // {_rootAliases = exports;}
