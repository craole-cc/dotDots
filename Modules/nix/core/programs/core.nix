{
  config,
  lix,
  lib,
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

  inherit (lix.modules.construction) mkIf;
  inherit (lix.modules.core.programs) mkPrograms;
  payload = mkPrograms {
      inherit (iface) windowManager;
      # enableHyprlandUWSM defaults to true in mkPrograms; override here
      # if a top-level option is ever added to ${top}.programs.hyprland.
    };
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = iface.enable;
  });
}
