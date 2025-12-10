{_, ...}: let
  mkVal = _.lists.makeCaseInsensitiveListValidator;
in {
  /**
  Desktop environments - complete desktop solutions.

  Full-featured desktop environments with integrated applications and settings.

  # Environments
  - none: No desktop environment (WM only or minimal setup)
  - gnome: GNOME desktop (GTK, modern, touch-friendly)
  - cosmic: System76 Cosmic (Rust-based, modern)
  - plasma: KDE Plasma (Qt, highly customizable)
  - xfce: Lightweight desktop (GTK, traditional)
  - budgie: Modern desktop (GNOME-based, clean)
  - mate: Traditional desktop (GNOME 2 fork)
  - cinnamon: Desktop environment (Linux Mint, traditional)
  - pantheon: Elementary OS desktop (macOS-like)
  - lxqt: Lightweight Qt desktop

  # Structure
  ```nix
  {
    values = [ "none" "gnome" "cosmic" "plasma" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate a desktop environment
  _lib.desktopEnvironments.validator.check { name = "GNOME"; }  # => true

  # Check multiple DEs
  _lib.isAnyInList ["gnome" "plasma"] _lib.desktopEnvironments.values true
  ```
  */
  desktopEnvironments = let
    values = [
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
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

  /**
  Window managers - standalone window management solutions.

  Manages window placement, focus, and behavior without a full desktop environment.

  # Categories
  - Wayland compositors: hyprland, niri, sway, river
  - X11 tiling: leftwm, qtile, i3, bspwm, dwm, awesome, xmonad
  - none: No window manager (terminal only or custom setup)

  # Structure
  ```nix
  {
    values = [ "none" "hyprland" "niri" "sway" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Validate a window manager
  _lib.windowManagers.validator.check { name = "Hyprland"; }  # => true

  # Check if WM is in list
  _lib.inList "sway" _lib.windowManagers.values
  ```
  */
  windowManagers = let
    values = [
      "none"
      "hyprland"
      "niri"
      "sway"
      "river"
      "leftwm"
      "qtile"
      "i3"
      "bspwm"
      "dwm"
      "awesome"
      "xmonad"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

  /**
  Wayland support - desktop environments/WMs with native Wayland support.

  Lists which desktop environments have mature Wayland implementations.
  Used for conditional Wayland-specific configuration.

  # Supported
  - gnome: Full Wayland support (default)
  - plasma: Wayland sessions available
  - sway: Native Wayland compositor (i3 replacement)
  - hyprland: Native Wayland compositor
  - river: Native Wayland compositor
  - leftwm: Native Wayland compositor

  # Structure
  ```nix
  {
    values = [ "gnome" "plasma" "sway" "hyprland" ... ];
    validator = { check, list };
  }
  ```

  # Usage
  ```nix
  # Check if DE/WM supports Wayland
  _lib.inList config.desktop _lib.waylandSupport.values

  # Validate Wayland support
  _lib.waylandSupport.validator.check { name = "sway"; }  # => true
  ```
  */
  waylandSupport = let
    values = [
      "gnome"
      "plasma"
      "sway"
      "hyprland"
      "river"
      "leftwm"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
}
