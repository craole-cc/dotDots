{
  name,
  system,
  nixosStable,
  nixosUnstable,
  homeManager,
  nixDarwin,
  path,
  args ? { },
  mods ? { },
  preferredRepo ? "unstable",
  allowUnfree ? true,
  allowAliases ? true,
  allowHomeManager ? true,
  enableDots ? false,
  extraPkgConfig ? { },
  extraPkgAttrs ? { },
}:
let
  isDarwin = builtins.match ".*darwin" system != null;
  specialArgs = args;
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
    let
      envNixPath = "${builtins.getEnv "NIX_PATH"}:${modules.host + "/${name}"}";
    in
    [ path ]
    ++ (
      if allowHomeManager then
        [
          {
            home-manager = {
              backupFileExtension = "BaC";
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
          (with homeManager; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
        ]
      else
        [ ]
    )
    ++ lib.mkForce [
      mods
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
