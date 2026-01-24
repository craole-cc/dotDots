{
  inputs,
  system,
  preferredRepo,
  allowUnfree,
  allowAliases,
  extraConfig ? {},
  extraPkgAttrs ? {},
  ...
}: let
  inherit
    (inputs)
    nixPackagesStable
    nixPackagesUnstable
    nixosHome
    nixosDarwin
    ;
  isDarwin = builtins.match ".*darwin" system != null;
  hasHomeManager = inputs ? nixosHome;

  mkPkgs = pkgsInput:
    import pkgsInput {
      inherit system;
      config =
        {
          inherit allowUnfree allowAliases;
        }
        // extraConfig;
    };

  nixpkgs =
    if preferredRepo == "stable"
    then nixPackagesStable
    else nixPackagesUnstable;

  lib =
    nixpkgs.lib
    // (
      if isDarwin
      then nixosDarwin.lib
      else {}
    )
    // (
      if hasHomeManager
      then nixosHome.lib
      else {}
    );

  defaultPkgs = mkPkgs nixpkgs;
in
  defaultPkgs.extend (
    _final: _prev:
      {
        stable = mkPkgs nixPackagesStable;
        unstable = mkPkgs nixPackagesUnstable;
        inherit lib;
      }
      // extraPkgAttrs
  )
