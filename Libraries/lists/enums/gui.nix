{_, ...}: let
  inherit (_.lists.generators) mkEnum;
  inherit (_.trivial.tests) mkTest runTests;

  /**
  Boot loaders - system boot manager options.

  Defines which bootloader manages system startup.

  # Loaders
  - systemd-boot: Simple UEFI boot manager (recommended for EFI systems)
  - grub: GNU GRUB (supports both BIOS and UEFI)
  - refind: rEFInd boot manager (UEFI only, graphical)

  # Structure
  ```nix
  {
    values = [ "systemd-boot" "grub" "refind" ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate bootloader
  _lib.bootLoaders.validator.check { name = "systemd-boot"; }  # => true

  # Check if using UEFI-compatible bootloader
  _lib.inList config.bootLoader ["systemd-boot" "refind"]
  ```
  */
  bootLoaders = mkEnum [
    "systemd-boot"
    "grub"
    "refind"
  ];

  /**
  Display protocols - graphics server protocols.

  Defines the underlying display server technology.

  # Protocols
  - wayland: Modern display protocol (better security, performance)
  - xserver: Traditional X11/X.org server (broader compatibility)
  - x11: Alias for X Window System

  # Structure
  ```nix
  {
    values = [ "wayland" "xserver" "x11" ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate display protocol
  _lib.displayProtocols.validator.check { name = "Wayland"; }  # => true

  # Check if using X11 (including alias)
  _lib.isAnyInList [config.displayProtocol] ["xserver" "x11"] true
  ```
  */
  displayProtocols = mkEnum {
    values = ["wayland" "xserver"];
    aliases.x11 = "xserver";
  };

  /**
  Display managers - display/session managers.

  Handles user authentication and session initialization.

  # Modern
  - sddm: Simple Desktop Display Manager (Qt-based, KDE default)
  - gdm: GNOME Display Manager (GTK-based)
  - cosmic-greeter: Cosmic Desktop display manager
  - greetd: Minimal, agnostic display manager

  # Lightweight
  - lightdm: Lightweight cross-desktop manager
  - ly: TUI display manager written in C

  # Legacy/Alternative
  - kmscon: KMS/DRM-based system console
  - xdm: X Display Manager (minimal)

  # Structure
  ```nix
  {
    values = [ "sddm" "gdm" "cosmic" "cosmic-greeter" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate login manager
  _lib.loginManagers.validator.check { name = "SDDM"; }  # => true

  # Check if using graphical login manager
  _lib.inList config.loginManager ["sddm" "gdm" "lightdm"]
  ```
  */
  displayManagers = mkEnum {
    values = [
      "sddm"
      "gdm"
      "cosmic-greeter"
      "lightdm"
      "kmscon"
      "xdm"
      "greetd"
      "ly"
    ];
    aliases = {
      cosmic = "cosmic-greeter";
      gnome = "gdm";
      plasma = "sddm";
      kde = "sddm";
      lxqt = "sddm";
      lxde = "lightdm";
      pantheon = "lightdm";
      budgie = "lightdm";
    };
  };

  /**
  Desktop environments - complete desktop solutions.

  Full-featured desktop environments with integrated applications and settings.

  # Environments
  - none: No desktop environment (WM only or minimal setup)
  - gnome: GNOME desktop (GTK, modern, touch-friendly, Wayland-first)
  - plasma: KDE Plasma (Qt, highly customizable, mature Wayland support)
  - cosmic: System76 Cosmic (Rust-based, modern, native Wayland)
  - xfce: Lightweight desktop (GTK, traditional, X11-focused)
  - budgie: Modern desktop (GNOME-based, clean, elegant)
  - mate: Traditional desktop (GNOME 2 fork, lightweight)
  - cinnamon: Desktop environment (Linux Mint, traditional, Windows-like)
  - pantheon: Elementary OS desktop (macOS-like, elegant)
  - lxqt: Lightweight Qt desktop (modern look, low resources)
  - lxde: Lightweight X11 desktop (very lightweight, traditional)
  - deepin: Deepin Desktop Environment (beautiful, modern Chinese distro)
  - enlightenment: Unique desktop/WM hybrid (lightweight, eye-candy)

  # Usage
  ```nix
  # Validate a desktop environment
  _.lists.enums.desktop.desktopEnvironments.validator.check "GNOME"  # => true

  # Get all values
  _.lists.enums.desktop.desktopEnvironments.values

  # Check membership
  _.lists.predicates.isIn "plasma" _.lists.enums.desktop.desktopEnvironments.values
  ```
  */
  desktopEnvironments = mkEnum [
    "none"
    "gnome"
    "cosmic"
    "plasma"
    "xfce"
    "budgie"
    "mate"
    "cinnamon"
    "pantheon"
    "lxqt"
    "lxde"
    "deepin"
    "enlightenment"
  ];

  /**
  Window managers - standalone window management solutions.

  Manages window placement, focus, and behavior without a full desktop environment.

  # Wayland Compositors
  - hyprland: Modern tiling Wayland compositor (dynamic, animations)
  - niri: Scrollable-tiling Wayland compositor (unique workflow)
  - sway: i3-compatible Wayland compositor (stable, mature)
  - river: Dynamic tiling Wayland compositor (simple, efficient)
  - wayfire: 3D Wayland compositor (compiz-like effects)

  # X11 Tiling
  - i3: Manual tiling window manager (popular, well-documented)
  - bspwm: Binary space partitioning WM (scriptable)
  - dwm: Suckless dynamic WM (minimal, patched)
  - awesome: Dynamic WM with Lua configuration
  - xmonad: Haskell-based tiling WM (powerful, functional)
  - qtile: Python-based tiling WM (easy to configure)
  - leftwm: Lightweight tiling WM (Rust-based)

  # Stacking/Floating
  - openbox: Lightweight stacking WM (highly configurable)
  - fluxbox: Fast and light stacking WM
  - icewm: Lightweight stacking WM (Windows 95-like)

  # Other
  - none: No window manager

  # Usage
  ```nix
  _.lists.enums.desktop.windowManagers.validator.check "Hyprland"  # => true
  _.lists.predicates.isIn "sway" _.lists.enums.desktop.windowManagers.values
  ```
  */
  windowManagers = mkEnum [
    "none"
    #~@ Wayland compositors
    "hyprland"
    "niri"
    "sway"
    "river"
    "wayfire"

    #~@ X11 tiling
    "i3"
    "bspwm"
    "dwm"
    "awesome"
    "xmonad"
    "qtile"
    "leftwm"

    #~@ Stacking/floating
    "openbox"
    "fluxbox"
    "icewm"
  ];

  /**
  Wayland support - desktop environments/WMs with native Wayland support.

  Lists desktop environments and window managers with mature Wayland implementations.
  Used for conditional Wayland-specific configuration.

  # Fully Native Wayland
  - cosmic: System76 Cosmic (Wayland-only)
  - hyprland: Native Wayland compositor
  - niri: Native Wayland compositor
  - sway: Native Wayland compositor (i3 replacement)
  - river: Native Wayland compositor
  - wayfire: Native Wayland compositor

  # Mature Wayland Sessions
  - gnome: Full Wayland support (default since GNOME 42)
  - plasma: Wayland sessions available (mature as of Plasma 6)

  # Usage
  ```nix
  # Check if DE/WM supports Wayland
  _.lists.predicates.isIn config.desktop _.lists.enums.desktop.waylandSupport.values

  _.lists.enums.desktop.waylandSupport.validator.check "sway"  # => true
  ```
  */
  waylandSupport = mkEnum [
    #~@ Desktops
    "gnome"
    "plasma"
    "cosmic"

    #~@ Compositors
    "hyprland"
    "niri"
    "sway"
    "river"
    "wayfire"
  ];
in {
  inherit
    bootLoaders
    displayProtocols
    displayManagers
    desktopEnvironments
    windowManagers
    waylandSupport
    ;

  _rootAliases = {
    bootLoadersList = bootLoaders.values;
    displayProtocolsList = displayProtocols.values;
    displayManagersList = displayManagers.values;
    desktopEnvironmentsList = desktopEnvironments.values;
    windowManagersList = windowManagers.values;
    waylandSupportedEnviromnentsList = waylandSupport.values;
  };

  _tests = runTests {
    bootLoaders = {
      validatesSystemdBoot = mkTest true (bootLoaders.validator.check "systemd-boot");
      validatesGrub = mkTest true (bootLoaders.validator.check "grub");
    };

    displayProtocols = {
      validatesWayland = mkTest true (displayProtocols.validator.check "wayland");
      validatesXserver = mkTest true (displayProtocols.validator.check "x11");
    };

    displayManagers = {
      validatesSDDM = mkTest true (displayManagers.validator.check "sddm");
      validatesGDM = mkTest true (displayManagers.validator.check "gdm");
    };

    desktopEnvironments = {
      validatesGnome = mkTest true (desktopEnvironments.validator.check "gnome");
      validatesCaseInsensitive = mkTest true (desktopEnvironments.validator.check "GNOME");
      rejectsInvalid = mkTest false (desktopEnvironments.validator.check "invalid");
      containsNone = mkTest true (_.lists.predicates.isIn "none" desktopEnvironments.values);
      containsAllMajor = mkTest true (_.lists.predicates.hasAll ["gnome" "plasma" "xfce"] desktopEnvironments.values);
      correctCount = mkTest 13 (builtins.length desktopEnvironments.values);
    };

    windowManagers = {
      validatesHyprland = mkTest true (windowManagers.validator.check "hyprland");
      validatesCaseInsensitive = mkTest true (windowManagers.validator.check "SWAY");
      rejectsInvalid = mkTest false (windowManagers.validator.check "invalid");
      containsWaylandCompositors = mkTest true (_.lists.predicates.hasAll ["hyprland" "sway" "river"] windowManagers.values);
      containsTilingWMs = mkTest true (_.lists.predicates.hasAll ["i3" "bspwm" "awesome"] windowManagers.values);
      correctCount = mkTest 16 (builtins.length windowManagers.values);
    };

    waylandSupport = {
      validatesGnome = mkTest true (waylandSupport.validator.check "gnome");
      validatesSway = mkTest true (waylandSupport.validator.check "sway");
      rejectsX11Only = mkTest false (waylandSupport.validator.check "xfce");
      containsCompositors = mkTest true (_.lists.predicates.hasAll ["hyprland" "sway" "river"] waylandSupport.values);
      containsDEs = mkTest true (_.lists.predicates.hasAll ["gnome" "plasma"] waylandSupport.values);
      correctCount = mkTest 8 (builtins.length waylandSupport.values);
    };
  };
}
