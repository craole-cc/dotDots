{
  inputs,
  lib,
  lix,
  path,
  pkgs,
  system,
  ...
}: let
  #> Metadata & Dependency Injection
  dots = {
    #~@ Functions
    inherit inputs lib lix path pkgs system;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (pkgs) mkShell;
    inputPkgs = input:
      lix.sources.packages.fromInputs {
        inherit input inputs system;
      };

    #~@ Metadata
    name = "dotDots";
    version = "2.0.0";
    cache = ".cache";
    prefix = ".";

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
    inherit (lib.attrsets) filterAttrs mapAttrs mapAttrs' nameValuePair;
    inherit (lib.filesystem) readDir;
    inherit (lib.lists) elem;
    inherit (lib.strings) hasSuffix hasPrefix removeSuffix;
    inherit (pkgs) mkShell;

    #> Filter out internal logic, archives, and formatting files
    files = let
      all = readDir ./.;
      valid = filterAttrs (name: kind:
        (kind == "regular")
        && hasSuffix ".nix" name
        && !(elem name ["default.nix" "fmt.nix"])
        && !(hasPrefix "archive" name)
        && !(hasPrefix "review" name))
      all;
    in
      valid;

    #> Import the attrs from the valididated files
    configs = mapAttrs' (name: _:
      nameValuePair
      (removeSuffix ".nix" name)
      (import (./. + "/${name}") {inherit dots;}))
    files;

    #> Build the final derivations
    shells = mapAttrs (name: cfg:
      mkShell {
        name = "${dots.name}-${name}";
        env = cfg.env or {};
        shellHook = cfg.shellHook or "";
        packages = (cfg.packages or []) ++ formatters;
      })
    configs;
  in
    shells // {default = shells.minimal;};
in {inherit checks devShells formatter;}
