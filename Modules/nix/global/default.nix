{
  inputs,
  lib,
  lix,
  paths,
  pkgs,
  system,
  ...
}: let
  #> Metadata & Dependency Injection
  dots = {
    #~@ Metadata
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";

    #~@ Imports
    inherit
      inputs
      lib
      lix
      system
      ;
    inherit (paths) src;

    #~@ Packages
    inherit pkgs formatters;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inputPkgs = input:
      lix.sources.packages.fromInputs {
        inherit input inputs system;
      };

    #~@ Options
    allowAI = true;
  };

  #~@ Global formatting tools
  inherit
    (import ./fmt.nix {inherit dots;})
    formatters
    formatter
    checks
    ;

  #~@ Shell Logic Consolidation
  devShells = let
    inherit
      (lib.attrsets)
      filterAttrs
      mapAttrs
      mapAttrs'
      nameValuePair
      ;
    inherit (lib.filesystem) readDir;
    inherit (lib.lists) elem;
    inherit (lib.strings) hasSuffix hasPrefix removeSuffix;
    inherit (pkgs) mkShell;

    #> Filter out internal logic, archives, and formatting files
    files = let
      all = readDir ./.;
      valid =
        filterAttrs (
          name: type:
          # pathIsRegularFile name
            (type == "regular")
            && hasSuffix ".nix" name
            && !(elem name [
              "default.nix"
              "fmt.nix"
            ])
            && !(hasPrefix "archive" name)
            && !(hasPrefix "review" name)
        )
        all;
    in
      valid;

    #> Import the attrs from the valididated files
    configs =
      mapAttrs' (
        file: _: nameValuePair (removeSuffix ".nix" file) (import (./. + "/${file}") {inherit dots;})
      )
      files;

    #> Build the final derivations
    shells =
      mapAttrs (
        name: cfg:
          mkShell {
            name = "${dots.name}-${name}";
            env = cfg.env or {};
            shellHook = cfg.shellHook or "";
            packages = cfg.packages or [];
          }
      )
      configs;
  in
    shells // {default = shells.full;};
in {inherit checks devShells formatter;}
