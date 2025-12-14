{
  _,
  lib,
  ...
}: let
  inherit (lib.attrsets) filterAttrs mapAttrs attrValues attrByPath;
  inherit (lib.lists) any concatLists elem head optional unique;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) hasInfix;
  inherit (_.generators.firefox) zenVariant;
  inherit (_.attrsets.resolution) getPackage;

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
          modules =
            [{system = {inherit (host) stateVersion;};}]
            # ++ host.imports
            ++ [
              inputs.nixosHome.nixosModules.home-manager
              {
                home-manager = {
                  backupFileExtension = "BaC";
                  overwriteBackup = true;
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = args;
                };
              }
            ]
            ++ [
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
    #> Merge user config from API/users/ with host-specific settings
    users =
      mapAttrs (
        name: config: allUsers.${name} or {} // config
      )
      (filterAttrs (_: cfg: cfg.enable or false) hostUsers);

    #> Collect all enabled regular users (non-service, non-guest)
    regularUsers = filterAttrs (_: u: !(elem u.role ["service" "guest"])) users;

    hyprlandNeeded = any (
      cfg: ((cfg.interface or {}).windowManager or "") == "hyprland"
    ) (attrValues regularUsers);

    #> Collect all unique shells from all users
    allShells = let
      shellsList = concatLists (
        attrValues (mapAttrs (_: cfg: cfg.shells or ["bash"]) users)
      );
    in
      unique shellsList;
  in {
    # imports = [../../Configuration/hosts/QBX/configuration.nix]; # TODO: Temporary until all setting are migrated.
    # inherit (host) imports;

    #~@ System-wide NixOS users
    users.users =
      mapAttrs
      (username: cfg: {
        isNormalUser = cfg.role != "service";
        isSystemUser = cfg.role == "service";
        description = cfg.description or username;
        #> Use first shell as default
        shell = getPackage {
          inherit pkgs;
          target = head (cfg.shells or ["bash"]);
        };
        password = cfg.password or null;
        extraGroups =
          if elem cfg.role ["admin" "administrator"]
          then ["wheel"]
          else [];
      })
      users;

    #~@ System-wide programs (not per-user)
    programs.hyprland = mkIf hyprlandNeeded {
      enable = true;
      withUWSM = true;
    };
    environment.systemPackages = mkIf hyprlandNeeded [pkgs.kitty];

    home-manager.users =
      mapAttrs
      (name: cfg: let
        zen = zenVariant (attrByPath ["applications" "browser" "firefox"] null cfg);
        de = attrByPath ["interface" "desktopEnvironment"] null cfg;
        wm = attrByPath ["interface" "windowManager"] null cfg;
      in {
        imports =
          []
          #> Add Firefox Zen module if user prefers the Zen variant.
          ++ (
            optional (zen != null)
            inputs.firefoxZen.homeModules.${zen}
          )
          #> Add Plasma Manager module if user uses Plasma desktop
          ++ optional (de == "plasma")
          inputs.plasmaManager.homeModules.plasma-manager
          ++ [];

        home = {
          inherit stateVersion;
          sessionVariables.USER_ROLE = cfg.role or "user";
          packages = map (shell:
            getPackage {
              inherit pkgs;
              target = shell;
            })
          allShells;
        };

        #> Enable shells in home-manager
        programs = {
          starship.enable = hasInfix "starship" (cfg.interface.prompt or "");
          oh-my-posh.enable = hasInfix "posh" (cfg.interface.prompt or "");
          bash.enable = elem "bash" (cfg.shells or []);
          zsh.enable = elem "zsh" (cfg.shells or []);
          fish.enable = elem "fish" (cfg.shells or []);
          nushell.enable = elem "nushell" (cfg.shells or []);
          zen-browser =
            mkIf (zen != null) {
              enable = true;
              package =
                if zen == null
                then null
                else inputs.firefoxZen.packages.${platform}.${zen} or
          (throw "Firefox Zen variant '${zen}' not found for system '${platform}'");
            };
        };

        wayland.windowManager.hyprland.enable = wm == "hyprland";
      }) (filterAttrs (_: u: !(elem u.role ["service" "guest"])) users);
  };
in {
  inherit
    mkHosts
    mkUsers
    ;
}
