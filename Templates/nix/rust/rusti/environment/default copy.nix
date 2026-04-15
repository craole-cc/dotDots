/**
modules/default.nix

Single entry point for all modules.
Owns mkOutputs so flake.nix stays bare.

lib is extended here once and threaded through all mk* functions,
so every module has access to lib.compactAttrs, lib.resolveBin, etc.

Returns: mkAll // { mkOutputs }
*/
{
  inputs,
  lib,
}: let
  inherit (lib.packages) mkPkgs;

  mkTools = import ./tools.nix;
  mkEnvironment = import ./environment.nix;
  mkTemplates = import ./templates.nix;
  mkWelcome = import ./welcome.nix;
  mkShells = import ./shells.nix;

  allMk = {
    inherit
      lib
      mkPkgs
      mkTools
      mkEnvironment
      mkTemplates
      mkWelcome
      mkShells
      ;
  };

  mkPerSystem = lib.attrsets.genAttrs [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  mkOutputs = {
    devShells = mkPerSystem (
      system: let
        pkgs = mkPkgs {inherit system;};
      in
        mkShells (allMk // {inherit pkgs;})
    );
  };
in
  allMk // {inherit mkOutputs;}
