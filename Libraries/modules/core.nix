{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;
  inherit (_.modules.hardware) mkAudio mkFileSystems mkNetwork;
  inherit (_.modules.software) mkBoot mkNix mkClean;
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

    #~@ Imports
    inherit (lib.attrsets) mapAttrs;
    inherit (lib.lists) optionals;
    inherit (lib.modules) evalModules;

    #~@ Modules
    modulesPath = "${nixpkgs}/nixos/modules";
    baseModules = import "${modulesPath}/module-list.nix";

    #~@ System
    eval = evalModules {
      inherit class;
      specialArgs = args' // {inherit modulesPath;};
      modules = baseModules ++ modules;

      # modules =
      #   baseModules
      #   ++ modules
      #   ++ [
      #     ({config, ...}: {
      #       config = {
      #         _module.args = {inherit baseModules modules;};
      #         inputs' =
      #           mapAttrs (
      #             _:
      #               mapAttrs (
      #                 _: v: v.${config.nixpkgs.hostPlatform.system} or v
      #               )
      #           )
      #           inputs;
      #         nixpkgs.flake.source = nixpkgs.outPath;
      #       };
      #     })
      #   ]
      #   ++ optionals (class == "darwin") [
      #     {
      #       config = {
      #         nixpkgs.source = nixpkgs.outPath;
      #         system = {
      #           checks.verifyNixPath = false;
      #           darwinVersionSuffix = ".${darwin.shortRev or darwin.dirtyShortRev or "dirty"}";
      #           darwinRevision = darwin.rev or darwin.dirtyRev or "dirty";
      #         };
      #       };
      #     }
      #   ];
    };
  in
    if class == "darwin"
    then (eval // {system = eval.config.system.build.toplevel;})
    else eval;

  mkCore = {
    hosts,
    args,
    ...
  }:
    mapAttrs (_name: host: let
      specialArgs =
        args
        // {
          inherit host;
          inherit (host) system;
        };
      inherit (specialArgs) inputs src;
    in
      mkSystem {
        inputs = specialArgs.rawInputs;
        inherit specialArgs;
        modules =
          [
            {
              imports = with inputs.modules.core; [home-manager];

              #> Configure nixpkgs with overlays and allowUnfree
              config = mkNix {inherit host inputs;};
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

  mkCoreORIG = {
    hosts,
    args,
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
              imports = with inputs.modules.core; [home-manager];

              #> Configure nixpkgs with overlays and allowUnfree
              config = mkNix {inherit host inputs;};
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
