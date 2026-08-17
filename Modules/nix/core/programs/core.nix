{
  config,
  lix,
  top,
  ...
}: let
  # Bridge module: no new ${top}.programs.* options are declared here.
  # Existing leaf modules (bash.nix, direnv.nix, git.nix, obs.nix,
  # starship.nix) remain the authoritative public option surface.
  #
  # This module only wires the interface-derived programs that have no
  # leaf owner: hyprland, niri, and xwayland.
  iface = config.${top}.resolved.interface;

  inherit (lix.modules.construction) mkConfig;
  inherit (lix.modules.core.programs) mkPrograms;
in
  mkConfig {
    payload = mkPrograms {
      inherit (iface) windowManager;
      # enableHyprlandUWSM defaults to true in mkPrograms; override here
      # if a top-level option is ever added to ${top}.programs.hyprland.
    };
    condition = iface.enable;
  }
