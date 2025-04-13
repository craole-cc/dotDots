{ inputs, host, ... }:
let
  validateDesktop =
    desktop:
    let
      supportedDesktops = [
        "hyprland"
        "plasma"
        "xfce"
        "gnome"
        null
      ];
    in
    if desktop == null || builtins.elem desktop supportedDesktops then
      desktop
    else
      throw "Unsupported desktop environment: ${desktop}. Supported values are: ${toString supportedDesktops}";

  desktop = validateDesktop host.desktop;

  core =
    with inputs;
    [
      styleManager.nixosModules.stylix
    ]
    ++ (
      if desktop == "hyprland" then
        [ ]
      else if desktop == "gnome" then
        [ ]
      else if desktop == "plasma" then
        [
          # plasmaManager.homeManagerModules.plasma-manager
        ]
      else if desktop == "xfce" then
        [ ]
      else
        [ ]
    );

  home =
    if (host.allowHomeManager or true) then
      [
        (with inputs.nixosHome; if isDarwin then darwinModules.home-manager else nixosModules.home-manager)
        {
          home-manager.sharedModules =
            with inputs;
            if desktop == "hyprland" then
              [ ]
            else if desktop == "gnome" then
              [ ]
            else if desktop == "plasma" then
              [
                plasmaManager.homeManagerModules.plasma-manager
              ]
            else if desktop == "xfce" then
              [ ]
            else
              [ ];
        }
      ]
    else
      [ ];
in
core ++ home
