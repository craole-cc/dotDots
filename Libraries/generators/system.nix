{...}: let
  mkHost = {
    name,
    host,
    args,
  }: let
    inherit (args) inputs;
    inherit (inputs.nixosCore) lib;
    inherit (lib) nixosSystem;
    inherit (lib.attrsets) filterAttrs mapAttrs;
    inherit (lib.lists) elem;
  in
    nixosSystem {
      system = host.specs.platform;
      specialArgs = args;
      modules = with inputs; [
        # ./Configuration/hosts/${name}/configuration.nix # TODO: We won't need this when all is said and done
        nixosHome.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "backup";
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
                _: user: {osConfig, ...}: {
                  home = {
                    inherit (osConfig.system) stateVersion;
                    sessionVariables.USER_ROLE = user.role or "user";
                  };
                }
              )
              (
                filterAttrs (_: u:
                  (u.enable or false) && ! elem u.role ["service" "guest"])
                host.users
              );
          };
        }
      ];
    };
in {
  inherit mkHost;
}
