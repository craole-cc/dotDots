{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs attrValues;
  inherit (lib.lists) concatLists elem head optional unique;
  inherit (lib.modules) mkIf;
  inherit (_.generators.firefox) zenVariant;

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
              };
            }
            (mkUsers {
              allUsers = users;
              hostUsers = host.users;
              inherit (host) stateVersion;
              inherit (host.specs) platform;
              inherit inputs;
            })
          ];
        }
    )
    hosts;

  mkUsers = {
    allUsers,
    hostUsers,
    stateVersion,
    platform,
    inputs,
  }: {pkgs, ...}: let
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
      (name: cfg: let
        zen = rec {
          variant = zenVariant cfg.applications.browser.firefox;
          package =
            if variant == null
            then null
            else inputs.firefoxZen.packages.${platform}.${variant} or
          (throw "Firefox Zen variant '${variant}' not found for system '${platform}'");
        };
      in {
        imports =
          []
          #> Add Firefox Zen module if user prefers the Zen variant.
          ++ (
            optional (zen.variant != null)
            inputs.firefoxZen.homeModules.${zen.variant}
          )
          #> Add Plasma Manager module if user uses Plasma desktop
          ++ optional ((cfg.interface or {}).desktopEnvironment or "" == "plasma")
          inputs.plasmaManager.homeModules.plasma-manager
          ++ [];

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
          zen-browser = mkIf (zen.variant != null) {
            enable = true;
            inherit (zen) package;
          };
        };
      }) (filterAttrs (_: u: !(elem u.role ["service" "guest"])) users);
  };
in {
  inherit
    mkHosts
    mkUsers
    ;
}
