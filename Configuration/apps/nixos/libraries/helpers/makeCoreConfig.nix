{
  name,
  system,
  preferredRepo,
  allowUnfree,
  allowAliases,
  allowHomeManager,
  backupFileExtension,
  enableDots,
  extraPkgConfig,
  extraPkgAttrs,
  specialArgs,

  nixosStable,
  nixosUnstable,
  homeManager,
  nixDarwin,
  corePath,
  coreMods,
  homeMods,
  inputs,
}:
let
  isDarwin = builtins.match ".*darwin" system != null;
  pkgs =
    let
      mkPkgs =
        pkgsInput:
        import pkgsInput {
          inherit system;
          config = {
            inherit allowUnfree allowAliases;
          } // extraPkgConfig;
        };
      nixpkgs = if preferredRepo == "stable" then nixosStable else nixosUnstable;
      lib = if allowHomeManager then nixpkgs.lib // homeManager.lib else nixpkgs.lib;
      defaultPkgs = mkPkgs nixpkgs;
      unstablePkgs = mkPkgs nixosUnstable;
      stablePkgs = mkPkgs nixosStable;
    in
    defaultPkgs.extend (
      final: prev:
      {
        stable = stablePkgs;
        unstable = unstablePkgs;
        inherit lib;
      }
      // extraPkgAttrs
    );
  lib = pkgs.lib;
  modules =
    [ corePath ]
    ++ (
      if allowHomeManager then
        [
          (with homeManager; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
          {
            home-manager = {
              inherit backupFileExtension;
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                # homeMods
                inputs.plasmaManager.homeManagerModules.plasma-manager
              ];
            };
          }
        ]
      else
        [ ]
    )
    ++ [
      coreMods
    ];
in
if isDarwin then
  lib.darwinSystem {
    inherit
      system
      pkgs
      lib
      modules
      specialArgs
      ;
  }
else
  lib.nixosSystem {
    inherit
      system
      pkgs
      lib
      modules
      specialArgs
      ;
  }
