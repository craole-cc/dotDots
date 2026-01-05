{
  lib,
  config,
  nixosConfig,
}: let
  inherit (lib.attrsets) hasAttrByPath;
  isEnabled = app:
    (
      (hasAttrByPath ["programs" app "enable"] config)
      && config.programs.${app}.enable
    )
    || (
      (hasAttrByPath ["services" app "enable"] config)
      && config.services.${app}.enable
    )
    || (
      (hasAttrByPath ["services" app "enable"] nixosConfig)
      && nixosConfig.services.${app}.enable
    )
    || (
      (hasAttrByPath ["services" app "enable"] nixosConfig)
      && nixosConfig.services.${app}.enable
    )
    || (
      (hasAttrByPath ["wayland" "windowManager" app "enable"] config)
      && config.wayland.windowManager.${app}.enable
    );
in {
  general = {
    allowPanelsOnScreenWithoutBar = true;
    animationDisabled = false;
    animationSpeed = 1;
    # avatarImage = toString "${pkgs.nixos-artwork}/share/artwork/logo/nix-snowflake.svg";
    boxRadiusRatio = 1;
    compactLockScreen = false;
    dimmerOpacity = 0.2;
    enableShadows = true;
    forceBlackScreenCorners = false;
    iRadiusRatio = 1;
    language = "";
    lockOnSuspend = true;
    radiusRatio = 1;
    scaleRatio = 1;
    screenRadiusRatio = 1;
    shadowDirection = "bottom_right";
    shadowOffsetX = 2;
    shadowOffsetY = 3;
    showHibernateOnLockScreen = false;
    showScreenCorners = true;
    showSessionButtonsOnLockScreen = true;
  };

  network = {
    wifiEnabled = nixosConfig.networking.networkmanager.enable;
  };

  templates = {
    enableUserTemplates = true;
    gtk = true;
    qt = true;

    alacritty = isEnabled "alacritty";
    cava = isEnabled "cava";
    code = isEnabled "vscode";
    discord = isEnabled "discord";
    emacs = isEnabled "emacs";
    foot = isEnabled "foot";
    fuzzel = isEnabled "fuzzel";
    ghostty = isEnabled "ghostty";
    helix = isEnabled "helix";
    hyprland = isEnabled "hyprland";
    kcolorscheme = isEnabled "kcolorscheme";
    kitty = isEnabled "kitty";
    mango = isEnabled "mango";
    niri = isEnabled "niri";
    pywalfox = isEnabled "pywal";
    spicetify = isEnabled "spicetify";
    telegram = isEnabled "telegram";
    vicinae = isEnabled "vicinae";
    walker = isEnabled "walker";
    wezterm = isEnabled "wezterm";
    yazi = isEnabled "yazi";
    zed = isEnabled "zed-editor";
  };

  ui = {
    bluetoothDetailsViewMode = "grid";
    bluetoothHideUnnamedDevices = false;
    fontDefault = "Monaspace Radon Var";
    fontDefaultScale = 0.95;
    fontFixed = "Maple Mono NF";
    fontFixedScale = 1;
    panelBackgroundOpacity = 0.97;
    panelsAttachedToBar = true;
    settingsPanelMode = "attached";
    tooltipsEnabled = true;
    wifiDetailsViewMode = "grid";
  };
}
