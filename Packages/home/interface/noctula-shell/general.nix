{}: {
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
    showScreenCorners = false;
    showSessionButtonsOnLockScreen = true;
  };

  network = {
    wifiEnabled = true; # TODO: make this dynamic to the host
  };

  templates = {
    alacritty = true;
    cava = true;
    code = true;
    discord = true;
    emacs = true;
    enableUserTemplates = true;
    foot = true;
    fuzzel = true;
    ghostty = true;
    gtk = true;
    helix = true;
    hyprland = true;
    kcolorscheme = true;
    kitty = true;
    mango = true;
    niri = true;
    pywalfox = true;
    qt = true;
    spicetify = true;
    telegram = true;
    vicinae = true;
    walker = true;
    wezterm = true;
    yazi = true;
    zed = true;
  };

  ui = {
    bluetoothDetailsViewMode = "grid";
    bluetoothHideUnnamedDevices = false;
    fontDefault = "Monaspace Radon Var";
    fontDefaultScale = 0.9;
    fontFixed = "Maple Mono NF";
    fontFixedScale = 1;
    panelBackgroundOpacity = 0.93;
    panelsAttachedToBar = true;
    settingsPanelMode = "attached";
    tooltipsEnabled = true;
    wifiDetailsViewMode = "grid";
  };
}
