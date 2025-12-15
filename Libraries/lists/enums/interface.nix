{_, ...}: let
  mkVal = _.mkCaseInsensitiveListValidator;
in {
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
  bootLoaders = let
    values = [
      "systemd-boot"
      "grub"
      "refind"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

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
  displayProtocols = let
    values = [
      "wayland"
      "xserver"
      "x11"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };

  /**
  Login managers - display/session managers.

  Handles user authentication and session initialization.

  # Managers
  - sddm: Simple Desktop Display Manager (Qt-based, KDE default)
  - gdm: GNOME Display Manager (GTK-based)
  - cosmic: Cosmic Desktop display manager
  - cosmic-greeter: Cosmic greeter (alias)
  - lightdm: Lightweight cross-desktop manager
  - kmscon: KMS/DRM-based system console
  - xdm: X Display Manager (minimal, legacy)
  - greetd: Minimal, agnostic display manager
  - ly: TUI display manager written in C

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
  loginManagers = let
    values = [
      "sddm"
      "gdm"
      "cosmic"
      "cosmic-greeter"
      "lightdm"
      "kmscon"
      "xdm"
      "greetd"
      "ly"
    ];
  in {
    inherit values;
    validator = mkVal values;
  };
}
