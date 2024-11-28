{
  name,
  preferredRepo ? "unstable",
  system,
  nixosStable,
  nixosUnstable,
  homeManager,
  nixDarwin,
  allowUnfree ? true,
  allowAliases ? true,
  allowHomeManager ? true,
  enableDots ? false,
  configPath,
  configArgs ? { },
  configMods ? { },
  extraPkgConfig ? { },
  extraPkgAttrs ? { },
}:
let
  isDarwin = builtins.match ".*darwin" system != null;
  specialArgs = configArgs;
  mods = {
    core = configPath;
    home = {
      forAll = {
        home-manager = {
          backupFileExtension = "BaC";
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      };
      forDarwin = homeManager.darwinModules.home-manager;
      forNixos = homeManager.nixosModules.home-manager;
    };
    config = configMods;
  };
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
    [ configPath ]
    ++ (
      if allowHomeManager then
        with mods.home;
        [
          forAll
          (if isDarwin then forDarwin else forNixos)
        ]
      else
        [ ]
    )
    ++ [
      configMods
      (if enableDots then { DOTS.hosts.${name}.enable = true; } else { })
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
