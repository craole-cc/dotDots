{
  self,
  inputs,
  paths,
  ...
}: name: extraArgs: let
  host = let
    inherit (lib.lists) foldl' filter;
    confCommon = import (paths.store.configuration.hosts + "/common");
    confSystem = import (paths.store.configuration.hosts + "/${name}");
    enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
    userConfigs =
      foldl' (
        acc: username:
          acc
          // {
            ${username} = import (paths.store.configuration.users + "/${username}");
          }
      ) {}
      enabledUsers;
  in
    {inherit name userConfigs;} // confCommon // confSystem // extraArgs;
  hostPaths = paths.updateLocalPaths (host.flake or null);
  system = host.platform;
  isDarwin = builtins.match ".*darwin" system != null;
  pkgs = import ./packages.nix {
    inherit inputs system;
    preferredRepo = host.preferredRepo or "unstable";
    allowUnfree = host.allowUnfree or true;
    allowAliases = host.allowAliases or true;
    extraConfig = host.extraPkgConfig or {};
    extraPkgAttrs = host.extraPkgAttrs or {};
  };
  specialArgs = {
    inherit inputs host;
    flake = self;
    paths = hostPaths;
  };
  modules = with paths.store.modules; [base];
  #   import ./modules.nix {
  #     inherit
  #       lib
  #       inputs
  #       paths
  #       host
  #       pkgs
  #       specialArgs
  #       ;
  #     backupFileExtension = host.backupFileExtension or "backup";
  #   }
  #   // import ./desktop.nix { inherit inputs host; };
  inherit (pkgs) lib;
  mkSystem = with lib;
    if isDarwin
    then darwinSystem
    else nixosSystem;
in
  mkSystem {
    inherit
      system
      pkgs
      lib
      modules
      specialArgs
      ;
  }
