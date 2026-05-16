{...}: let
  exports = {
    internal = {inherit mkPrograms;};
    external = {mkCorePrograms = mkPrograms;};
  };

  /**
    Build a NixOS configuration fragment for interface-derived programs.

    Covers only programs that have no leaf module owner: the active window
    manager and XWayland. All other programs (bash, direnv, git, starship,
    obs-studio) are owned by their respective leaf modules under
    Modules/nix/core/programs/ and must not be emitted here.

    # Type
  ```nix
    mkPrograms :: {
      windowManager      :: String | null,
      enableHyprlandUWSM :: Bool,
    } -> AttrSet
  ```

    # Examples
  ```nix
    mkPrograms { windowManager = "hyprland"; enableHyprlandUWSM = true; }
    # => {
    #   programs.hyprland = { enable = true; withUWSM = true; };
    #   programs.niri.enable = false;
    #   programs.xwayland.enable = true;
    # }
  ```
  */
  mkPrograms = {
    windowManager ? null,
    enableHyprlandUWSM ? true,
    ...
  }: {
    programs = {
      hyprland = {
        enable = windowManager == "hyprland";
        withUWSM = enableHyprlandUWSM;
      };
      niri.enable = windowManager == "niri";
      xwayland.enable = true;
    };
  };
in
  exports.internal // {__rootAliases = exports.external;}
