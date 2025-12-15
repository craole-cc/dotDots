{
  lib,
  _,
  ...
}: let
  inherit (_.lists.generators) mkCaseInsensitiveListValidator;

  # Helper to create enum with validator
  mkEnum = values: {
    inherit values;
    validator = mkCaseInsensitiveListValidator values;
  };

  /**
  Desktop environments - complete desktop solutions.

  Full-featured desktop environments with integrated applications and settings.

  # Environments
  - none: No desktop environment (WM only or minimal setup)
  - gnome: GNOME desktop (GTK, modern, touch-friendly, Wayland-first)
  - cosmic: System76 Cosmic (Rust-based, modern, native Wayland)
  - plasma: KDE Plasma (Qt, highly customizable, mature Wayland support)
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
    # Wayland compositors
    "hyprland"
    "niri"
    "sway"
    "river"
    "wayfire"
    # X11 tiling
    "i3"
    "bspwm"
    "dwm"
    "awesome"
    "xmonad"
    "qtile"
    "leftwm"
    # Stacking/floating
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
    # Desktop environments
    "gnome"
    "plasma"
    "cosmic"
    # Wayland compositors
    "hyprland"
    "niri"
    "sway"
    "river"
    "wayfire"
  ];
  exports = {inherit desktopEnvironments windowManagers waylandSupport;};
in
  exports
  // {
    _rootAliases = {
      desktopEnvironmentsList = desktopEnvironments.values;
      desktopEnvironmentsCheck = desktopEnvironments.validator;
      windowManagersList = windowManagers.values;
      windowManagersCheck = windowManagers.validator;
      waylandSupportList = waylandSupport.values;
      waylandSupportCheck = waylandSupport.validator;
    };
    _tests = let
      inherit (_.testing.unit) mkTest runTests;
    in
      runTests {
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
