{
  self,
  inputs,
  paths,
  # lib,
  ...
}:
name: extraArgs:
let
  host =
    let
      inherit (lib.lists) foldl' filter;
      confCommon = import (paths.conf.hosts + "/common");
      confSystem = import (paths.conf.hosts + "/${name}");
      enabledUsers = map (user: user.name) (filter (user: user.enable or true) confSystem.people);
      userConfigs = foldl' (
        acc: username:
        acc
        // {
          ${username} = import (paths.conf.users + "/${username}");
        }
      ) { } enabledUsers;
    in
    { inherit name userConfigs; } // confCommon // confSystem // extraArgs;

  system = host.platform;
  isDarwin = builtins.match ".*darwin" system != null;
  pkgs = import ./mkPackages.nix {
    inherit inputs system;
    preferredRepo = host.preferredRepo or "unstable";
    allowUnfree = host.allowUnfree or true;
    allowAliases = host.allowAliases or true;
    extraConfig = host.extraPkgConfig or { };
    extraPkgAttrs = host.extraPkgAttrs or { };
  };
  specialArgs = {
    inherit inputs host;
    flake = self;
    paths =
      (lib.evalModules {
        modules = [
          {
            imports = [ paths.opts.paths ];
            config.DOTS.paths.base = host.flake or "/home/craole/.dots";
            _module.specialArgs.paths.base = host.flake or "/home/craole/.dots";
          }
        ];
      }).config.DOTS.paths;
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
  mkSystem = with lib; if isDarwin then darwinSystem else nixosSystem;
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
