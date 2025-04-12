{
  self,
  inputs,
  paths,
  # lib,
  ...
}:
name: extraArgs:
let
  basePath = extraArgs.basePath or "/home/craole/.dots";

  host =
    let
      inherit (lib.lists) foldl' filter;
      confCommon = import (paths.conf.hosts + "/common");
      confSystem = import (paths.conf.hosts + "/${name}");
      enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
      userConfigs = foldl' (
        acc: userFile: acc // import (paths.conf.users + "/${userFile}")
      ) { } enabledUsers;
    in
    {
      inherit name userConfigs;
    }
    // confCommon
    // confSystem
    // extraArgs;

  system = host.platform;
  isDarwin = builtins.match ".*darwin" system != null;
  pkgs = import ./mkPackages.nix {
    inherit inputs system;
    _module.specialArgs.DOTS.paths.base = basePath;
    preferredRepo = host.preferredRepo or "unstable";
    allowUnfree = host.allowUnfree or true;
    allowAliases = host.allowAliases or true;
    extraConfig = host.extraPkgConfig or { };
    extraPkgAttrs = host.extraPkgAttrs or { };
  };

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
