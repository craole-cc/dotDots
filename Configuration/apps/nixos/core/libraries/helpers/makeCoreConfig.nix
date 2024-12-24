{
  name,
  system,
  preferredRepo,
  allowUnfree,
  allowAliases,
  allowHomeManager,
  backupFileExtension,
  extraPkgConfig,
  extraPkgAttrs,

  specialArgs,
  specialModules,

  nixosStable,
  nixosUnstable,
  homeManager,
  nixDarwin,
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
      # lib = if allowHomeManager then nixpkgs.lib // homeManager.lib else if else nixpkgs.lib;
      lib =
        nixpkgs.lib
        // (if isDarwin then nixDarwin.lib else { })
        // (if allowHomeManager then homeManager.lib else { });
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
    specialModules.core
    ++ (
      if allowHomeManager then
        [
          (with homeManager; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
          {
            home-manager = {
              inherit backupFileExtension;
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = specialModules.home;
              extraSpecialArgs = specialArgs;
            };
          }
        ]
      else
        [ ]
    );
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
