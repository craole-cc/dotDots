{...}: let
  mkConfigurations = {
    hosts,
    args,
  }: let
    inherit (args) inputs;
    inherit (inputs.nixosCore) lib;
    inherit (lib) nixosSystem filterAttrs mapAttrs;
    inherit (lib.lists) elem;

    # For each host, return a nixosSystem
    hostSystems =
      mapAttrs
      (
        name: host:
          nixosSystem {
            system = host.specs.platform;
            specialArgs = args;
            modules = with inputs; [
              nixosHome.nixosModules.home-manager
              {
                home-manager = {
                  # backupFileExtension = "backup";
                  overwriteBackup = true;
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = args;
                  sharedModules = [
                    firefoxZen.homeModules.twilight
                    plasmaManager.homeModules.plasma-manager
                  ];
                  users =
                    mapAttrs
                    (
                      username: userCfg: {osConfig, ...}: {
                        home = {
                          inherit (osConfig.system) stateVersion;
                          sessionVariables.USER_ROLE = userCfg.role or "user";
                        };
                      }
                    )
                    (
                      filterAttrs
                      (
                        _: u:
                          (u.enable or false)
                          && ! elem (u.role or "user") ["service" "guest"]
                      )
                      host.users
                    );
                };
              }
              ./Configuration/hosts/${name}/configuration.nix
            ];
          }
      )
      hosts;
  in
    hostSystems;
in {
  inherit mkConfigurations;
}
