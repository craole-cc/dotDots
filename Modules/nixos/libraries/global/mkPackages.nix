{
  inputs,
  system,
  preferredRepo,
  allowUnfree,
  allowAliases,
  extraConfig ? { },
  extraPkgAttrs ? { },
  ...
}:
let
  isDarwin = builtins.match ".*darwin" system != null;
  hasHomeManager = inputs ? nixosHome; # Check if nixosHome exists in inputs

  mkPkgs =
    pkgsInput:
    import pkgsInput {
      inherit system;
      config = {
        inherit allowUnfree allowAliases;
      } // extraConfig;
    };

  nixpkgs =
    if preferredRepo == "stable" then inputs.nixPackagesStable else inputs.nixPackagesUnstable;

  lib =
    nixpkgs.lib
    // (if isDarwin then inputs.nixosDarwin.lib else { })
    // (if hasHomeManager then inputs.nixosHome.lib else { }); # Use hasHomeManager

  defaultPkgs = mkPkgs nixpkgs;
in
defaultPkgs.extend (
  final: prev:
  {
    stable = mkPkgs inputs.nixPackagesStable;
    unstable = mkPkgs inputs.nixPackagesUnstable;
    inherit lib;
  }
  // extraPkgAttrs
)
