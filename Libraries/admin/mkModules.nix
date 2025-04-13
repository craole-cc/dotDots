{
  lib,
  inputs,
  paths,
  host,
  backupFileExtension ? "backup",
  specialArgs ? { },
  ...
}:
let
  isDarwin = builtins.match ".*darwin" host.platform != null;
  stateVersion = host.stateVersion or "25.05";

  validateDesktop =
    desktop:
    let
      supportedDesktops = [
        "hyprland"
        "plasma"
        "xfce"
        null
      ];
    in
    if desktop == null || builtins.elem desktop supportedDesktops then
      desktop
    else
      throw "Unsupported desktop environment: ${desktop}. Supported values are: ${toString supportedDesktops}";

  inherit (host) desktop;
  validatedDesktop = validateDesktop desktop;

  core =
    [
      ./mkUsers.nix
      ./mkEnvironment.nix
      {
        system.stateVersion = stateVersion;
      }
    ]
    ++ (with paths; [
      base
      packages
      modules
      libraries
    ])
    ++ (with inputs; [
      nixLocate.nixosModules.nix-index
      styleManager.nixosModules.stylix
    ]);

  home =
    with inputs;
    if validatedDesktop == "hyprland" then
      [ ]
    else if validatedDesktop == "plasma" then
      [
        plasmaManager.homeManagerModules.plasma-manager
      ]
    else if validatedDesktop == "xfce" then
      [ ]
    else
      [ ];

  wslModule = lib.optional (host.wsl or false) {
    imports = [
      inputs.nixosWSL.nixosModules.default
      { wsl = host.wslConfig or { }; }
    ];
  };

  homeManagerModule =
    if (host.allowHomeManager or true) then
      [
        (with inputs.nixosHome; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
        {
          home-manager = {
            inherit backupFileExtension;
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = home;
            extraSpecialArgs = specialArgs;
            users = lib.genAttrs (builtins.attrNames host.userConfigs) (username: {
              home.stateVersion = stateVersion;
              programs.home-manager.enable = true;
            });
          };
        }
      ]
    else
      [ ];
in
core ++ wslModule ++ homeManagerModule
