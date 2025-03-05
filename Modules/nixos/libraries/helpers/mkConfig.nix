{
  self,
  inputs,
  paths,
  ...
}:
name: extraArgs:
let
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
  specialModules =
    let
      inherit (host) desktop;
      core =
        (with paths.core; [
          libraries
          modules
          options
        ])
        ++ (with inputs; [
          stylix.nixosModules.stylix
          nid.nixosModules.nix-index
        ]);
      home =
        with inputs;
        if desktop == "hyprland" then
          [ ]
        else if desktop == "plasma" then
          [ plasmaManager.homeManagerModules.plasma-manager ]
        else if desktop == "xfce" then
          [ ]
        else
          [ ];
    in
    {
      inherit core home;
    };

  specialArgs = {
    inherit self paths host;
    modules = specialModules;
    libraries = import paths.libraries.store; # TODO: Check on this
  };
in
import paths.libraries.mkCore {
  inherit (inputs)
    nixosStable
    nixosUnstable
    homeManager
    nixDarwin
    ;

  inherit (host)
    name
    # system
    ;

  inherit
    specialArgs
    specialModules
    ;

  system = host.platform;
  preferredRepo = host.preferredRepo or "unstable";
  allowUnfree = host.allowUnfree or true;
  allowAliases = host.allowAliases or true;
  allowHomeManager = host.allowHomeManager or true;
  backupFileExtension = host.backupFileExtension or "BaC";
  extraPkgConfig = host.extraPkgConfig or { };
  extraPkgAttrs = host.extraPkgAttrs or { };
}
