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
  extraMods,
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
    [
      corePath
    ]
    # ++ extraMods.core
    ++ (
      if allowHomeManager then
        [
          {
            home-manager = {
              inherit backupFileExtension;
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [ extraMods.home ];
            };
          }

          (with homeManager; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
        ]
      else
        [ ]
    )
    ++ [
      coreMods
      # (if enableDots then { DOTS.hosts.${name}.enable = true; } else { })
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
