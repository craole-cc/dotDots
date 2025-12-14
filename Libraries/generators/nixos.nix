{lib, ...}: let
  inherit (lib.attrsets) filterAttrs mapAttrs attrValues;
  inherit (lib.lists) concatLists elem head unique;

  mkHosts = {
    inputs,
    hosts,
    users,
    args,
  }:
    mapAttrs
    (
      name: host:
        inputs.nixosCore.lib.nixosSystem {
          system = host.specs.platform;
          specialArgs = args;
          modules = with inputs; [
            nixosHome.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "BaC";
                overwriteBackup = true;
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = args;
                sharedModules = [
                  firefoxZen.homeModules.twilight
                  plasmaManager.homeModules.plasma-manager
                ];
              };
            }
            (mkUsers users host.users host.stateVersion)
          ];
        }
    )
    hosts;

  mkUsers = allUsers: hostUsers: stateVersion: {pkgs, ...}: let
    #TODO: Move to Library
    # Helper function to get shell package from name
    getShellPackage = shellName:
      {
        "bash" = pkgs.bashInteractive;
        "nushell" = pkgs.nushell;
        "powershell" = pkgs.powershell;
        "zsh" = pkgs.zsh;
        "fish" = pkgs.fish;
        # Add more shells as needed
      }.${
        shellName
      } or pkgs.bashInteractive;

    #> Merge user config from API/users/ with host-specific settings
    users =
      mapAttrs (
        name: config: allUsers.${name} or {} // config
      )
      (filterAttrs (_: cfg: cfg.enable or false) hostUsers);

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) users)
      );
    in
      unique shellsList;
  in {
    users.users =
      mapAttrs
      (username: cfg: {
        isNormalUser = cfg.role != "service";
        isSystemUser = cfg.role == "service";
        description = cfg.description or username;
        #> Use first shell as default
        shell = getShellPackage (head (cfg.shells or ["bash"]));
        password = cfg.password or null;
        extraGroups =
          if elem cfg.role ["admin" "administrator"]
          then ["wheel"]
          else [];
      })
      users;

    home-manager.users =
      mapAttrs
      (name: cfg: {
        home = {
          inherit stateVersion;
          sessionVariables.USER_ROLE = cfg.role or "user";
          packages = map getShellPackage allShells;
        };

        #> Enable shells in home-manager
        programs = {
          bash.enable = elem "bash" (cfg.shells or []);
          zsh.enable = elem "zsh" (cfg.shells or []);
          fish.enable = elem "fish" (cfg.shells or []);
        };
      }) (filterAttrs (_: u: !(elem u.role ["service" "guest"])) users);
  };
in {
  inherit
    mkHosts
    mkUsers
    ;
}
