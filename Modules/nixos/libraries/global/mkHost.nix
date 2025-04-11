{
  self,
  inputs,
  paths,
  ...
}:
name: extraArgs:
let
  # Build host configuration
  host =
    let
      inherit (inputs.nixpkgs.lib.lists) foldl' filter;
      confCommon = import (paths.core.configurations.hosts + "/common");
      confSystem = import (paths.core.configurations.hosts + "/${name}");
      enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
      userConfigs = foldl' (
        acc: userFile: acc // import (paths.core.configurations.users + "/${userFile}")
      ) { } enabledUsers;
    in
    {
      inherit name userConfigs;
    }
    // confCommon
    // confSystem
    // extraArgs;

  # System setup
  system = host.platform;
  isDarwin = builtins.match ".*darwin" system != null;

  # Create packages
  pkgs = import ./mkPackages.nix {
    inherit inputs system;
    preferredRepo = host.preferredRepo or "unstable";
    allowUnfree = host.allowUnfree or true;
    allowAliases = host.allowAliases or true;
    extraConfig = host.extraPkgConfig or { };
    extraPkgAttrs = host.extraPkgAttrs or { };
  };

  # Special arguments
  specialArgs = {
    inherit inputs paths host;
    flake = self;
  };

  modules = import ./mkModules.nix {
    inherit
      lib
      inputs
      paths
      host
      pkgs
      specialArgs
      ;
    backupFileExtension = host.backupFileExtension or "backup";
  };

  inherit (pkgs) lib;
  
  systemFunc = if isDarwin then lib.darwinSystem else lib.nixosSystem;
in
systemFunc {
  inherit
    system
    pkgs
    lib
    modules
    specialArgs
    ;
}
