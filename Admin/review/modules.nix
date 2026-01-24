{
  lib,
  inputs,
  paths,
  host,
  backupFileExtension ? "backup",
  specialArgs ? {},
  ...
}: let
  inherit (lib.attrsets) genAttrs attrNames;
  isDarwin = builtins.match ".*darwin" host.platform != null;
  stateVersion = host.stateVersion or "25.05";

  coreModules =
    [
      {system = {inherit stateVersion;};}
      ./users.nix
    ]
    ++ (with paths.store.modules; [
      env
      nix
    ])
    ++ (with inputs; [
      nixLocate.nixosModules.nix-index
    ]);

  homeModules =
    if (host.allowHomeManager or true)
    then [
      (with inputs.nixosHome;
        if isDarwin
        then darwinModules.home-manager
        else nixosModules.home-manager)
      {
        home-manager = {
          inherit backupFileExtension;
          extraSpecialArgs = specialArgs;
          useGlobalPkgs = true;
          useUserPackages = true;
          users = genAttrs (attrNames host.userConfigs) (_username: {
            home.stateVersion = stateVersion;
            programs.home-manager.enable = true;
          });
          sharedModules = [
          ];
        };
      }
    ]
    else [];

  wslModules = lib.optional (host.wsl or false) {
    imports = [
      inputs.nixosWSL.nixosModules.default
      {wsl = host.wslConfig or {};}
    ];
  };
in
  coreModules ++ homeModules ++ wslModules
